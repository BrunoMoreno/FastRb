require_relative "rubyapi/version"
require_relative "rubyapi/router"
require_relative "rubyapi/context"
require_relative "rubyapi/param_converters"
require_relative "rubyapi/serializer"
require_relative "rubyapi/openapi"

module RubyAPI
  class App
    attr_reader :router

    def initialize(&block)
      @router = Router.new
      @middlewares = []
      @before_hooks = []
      @after_hooks = []
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
      return [404, { "content-type" => "application/json" }, ['{"error":"Not Found"}']] unless route

      ctx = Context.new(req, route)
      ctx.apply_param_types!
      return [ctx.response_status, ctx.response_headers.merge("content-type" => "application/json"), [JSON.generate(ctx.response_body)]] if ctx.response_status

      @before_hooks.each { |hook| hook.call(ctx) }
      result = route[:block].call(ctx)
      @after_hooks.each { |hook| hook.call(ctx) }

      ctx.response_body = result if result && !ctx.response_body

      serialize_response(ctx)
    end

    private

    def serialize_response(ctx)
      body = ctx.response_body
      status = ctx.response_status || 200
      headers = { "content-type" => "application/json" }.merge(ctx.response_headers)

      json = case body
      when Hash, Array then JSON.generate(body)
      when String then body
      else body.to_s
      end

      [status, headers, [json]]
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
          <title>RubyAPI Docs</title>
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
