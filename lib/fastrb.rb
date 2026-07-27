require_relative "fastrb/version"
require_relative "fastrb/router"
require_relative "fastrb/context"
require_relative "fastrb/param_converters"
require_relative "fastrb/serializer"
require_relative "fastrb/openapi"
require_relative "fastrb/schema"
require_relative "fastrb/session"
require_relative "fastrb/error_handler"
require_relative "fastrb/config"
require_relative "fastrb/di"
require_relative "fastrb/plugin"
require_relative "fastrb/websocket"
require_relative "fastrb/sse"
require_relative "fastrb/streaming"
require_relative "fastrb/job"
require_relative "fastrb/middleware/logging"
require_relative "fastrb/plugins/cors"
require_relative "fastrb/plugins/jwt"
require_relative "fastrb/plugins/auth"
require_relative "fastrb/plugins/cache"

module RubyAPI
  class App
    include ErrorHandler
    include DI

    attr_reader :router, :config, :container

    def initialize(&block)
      @router = Router.new
      @config = Config.new
      @container = Container.new
      @middlewares = []
      @before_hooks = []
      @after_hooks = []
      @error_handlers = {}
      @plugins = []
      instance_eval(&block) if block
    end

    def get(path, **opts, &block)
      @router.add_route(:GET, path, **opts, &block)
    end

    def post(path, **opts, &block)
      @router.add_route(:POST, path, **opts, &block)
    end

    def put(path, **opts, &block)
      @router.add_route(:PUT, path, **opts, &block)
    end

    def patch(path, **opts, &block)
      @router.add_route(:PATCH, path, **opts, &block)
    end

    def delete(path, **opts, &block)
      @router.add_route(:DELETE, path, **opts, &block)
    end

    def options(path, **opts, &block)
      @router.add_route(:OPTIONS, path, **opts, &block)
    end

    def head(path, **opts, &block)
      @router.add_route(:HEAD, path, **opts, &block)
    end

    def route(method, path, **opts, &block)
      @router.add_route(method, path, **opts, &block)
    end

    def websocket(path, &handler)
      @router.add_route(:GET, path, websocket: true, block: handler)
    end

    def group(prefix, &block)
      @router.push_prefix(prefix)
      instance_eval(&block)
      @router.pop_prefix(prefix)
    end

    def use(middleware, *args)
      @middlewares << [middleware, args]
    end

    def before(&hook)
      @before_hooks << hook
    end

    def after(&hook)
      @after_hooks << hook
    end

    def plugin(name_or_klass, **opts)
      klass = name_or_klass.is_a?(Class) ? name_or_klass : PluginRegistry.find(name_or_klass)
      return unless klass

      old_options = klass.options.dup
      opts.each { |k, v| klass.option(k, v) }

      @plugins << klass
      klass.on_load(self)
    rescue => e
      klass.options.replace(old_options) if old_options
      raise e
    end

    def register(name, &block)
      @container.register(name, &block)
    end

    def call(env)
      req = Rack::Request.new(env)
      path = req.path_info
      method = req.request_method.upcase

      if path == "/openapi.json"
        return serve_openapi
      end

      if path == "/docs"
        return serve_swagger_ui
      end

      route = @router.find(method, path)

      if route && route[:websocket] && env["HTTP_UPGRADE"]&.downcase == "websocket"
        return handle_websocket(env, route)
      end

      ctx = Context.new(req, route || dummy_route(req))

      @before_hooks.each do |hook|
        hook.call(ctx)
        if ctx.response_status
          return error_response(ctx)
        end
      end

      return [404, { "content-type" => "application/json" }, ['{"error":"Not Found"}']] unless route

      ctx.apply_param_types!
      return error_response(ctx) if ctx.response_status

      if route[:body]
        ctx.validate_body!(route[:body])
        return error_response(ctx) if ctx.response_status
      end

      session = Session.new(req, secret_key: @config.get(:secret_key))
      ctx.session = session

      inject_deps(ctx, route)
      return error_response(ctx) if ctx.response_status

      begin
        result = route[:block].call(ctx)
      rescue => e
        handler_status = find_error_handler(e)
        if handler_status
          set_session_cookie(ctx, session)
          return [handler_status, { "content-type" => "application/json" }, [JSON.generate({ error: e.class.name, message: e.message })]]
        end
        raise e
      end

      @after_hooks.each { |hook| hook.call(ctx) }
      ctx.response_body = result if result && !ctx.response_body

      set_session_cookie(ctx, session)
      serialize_response(ctx)
    end

    private

    def dummy_route(req)
      {
        method: req.request_method.upcase,
        path: req.path_info,
        pattern: /\A#{Regexp.escape(req.path_info)}\z/,
        param_names: [],
        block: nil,
        params: {},
        body: nil,
        inject: [],
        depends: [],
        websocket: false
      }
    end

    def handle_websocket(env, route)
      ws = WebSocket.new(env, &route[:block])
      hijack_io = env["rack.hijack"]&.call
      return [500, {}, ["rack.hijack not available"]] unless hijack_io

      ws_thread = Thread.new do
        ws.instance_variable_set(:@io, hijack_io)
        ws.process!
      end
      ws_thread.join

      [101, {}, []]
    rescue => e
      [500, { "content-type" => "application/json" }, [JSON.generate({ error: e.class.name, message: e.message })]]
    end

    def error_response(ctx)
      headers = { "content-type" => "application/json" }.merge(ctx.response_headers)
      body = case ctx.response_body
      when Hash, Array then JSON.generate(ctx.response_body)
      when String then ctx.response_body
      else ctx.response_body.to_s
      end
      [ctx.response_status, headers, [body]]
    end

    def inject_deps(ctx, route)
      deps = route[:injected_deps] || []
      deps.each do |name|
        resolved = @container.resolve(name)
        ctx.set(name, resolved)
      end

      checks = route[:dependency_checks] || []
      checks.each do |check_def|
        check_val = check_def[:check]
        status = check_def[:status] || 401

        allowed = case check_val
        when Proc
          check_val.call(ctx)
        when Symbol
          dep = @container.resolve(check_val)
          dep&.call(ctx)
        when Class
          check_val.new.call(ctx)
        else
          true
        end

        unless allowed
          ctx.response_status = status
          ctx.response_body = { error: "Forbidden" }
          return
        end
      end
    end

    def serialize_response(ctx)
      body = ctx.response_body
      status = ctx.response_status || 200
      headers = { "content-type" => "application/json" }.merge(ctx.response_headers)

      if body.is_a?(StreamingBody)
        [status, headers, body]
      else
        json = case body
        when Hash, Array then JSON.generate(body)
        when String then body
        else body.to_s
        end

        [status, headers, [json]]
      end
    end

    def set_session_cookie(ctx, session)
      cookie_value = session.serialize
      ctx.response_headers["set-cookie"] = "#{Session::SESSION_COOKIE}=#{cookie_value}; path=/; HttpOnly"
    end

    def find_error_handler(exception)
      @error_handlers.each do |klass, status|
        return status if exception.is_a?(klass)
      end
      nil
    end

    def serve_openapi
      spec = OpenAPI.new(self)
      [200, { "content-type" => "application/json" }, [spec.to_json]]
    end

    def serve_swagger_ui
      html = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>FastRb Docs</title>
          <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist/swagger-ui.css">
        </head>
        <body>
          <div id="swagger-ui"></div>
          <script src="https://unpkg.com/swagger-ui-dist/swagger-ui-bundle.js"></script>
          <script>
            SwaggerUIBundle({ url: "/openapi.json", dom_id: "#swagger-ui" });
          </script>
        </body>
        </html>
      HTML
      [200, { "content-type" => "text/html" }, [html]]
    end
  end
end
