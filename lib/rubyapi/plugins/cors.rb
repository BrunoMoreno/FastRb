module RubyAPI
  module Plugins
    class CORS < Plugin
      option :origins, ["*"]
      option :methods, ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
      option :headers, ["Content-Type", "Authorization"]
      option :allow_credentials, false
      option :max_age, 86400

      def self.on_load(app)
        allowed = options[:origins]
        methods = options[:methods].join(", ")
        headers = options[:headers].join(", ")
        credentials = options[:allow_credentials]
        max_age = options[:max_age]

        app.before do |ctx|
          origin = ctx.request.get_header("HTTP_ORIGIN")
          next unless allowed.include?("*") || allowed.include?(origin)

          ctx.response_headers["access-control-allow-origin"] = origin || "*"
          ctx.response_headers["access-control-allow-methods"] = methods
          ctx.response_headers["access-control-allow-headers"] = headers
          ctx.response_headers["access-control-allow-credentials"] = credentials.to_s if credentials
          ctx.response_headers["access-control-max-age"] = max_age.to_s

          if ctx.request.request_method == "OPTIONS"
            ctx.response_status = 204
            ctx.response_body = ""
          end
        end
      end
    end
  end
end
