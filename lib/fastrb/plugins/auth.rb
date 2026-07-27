module RubyAPI
  module Plugins
    class Auth < Plugin
      option :unauthorized_status, 401
      option :unauthorized_body, { error: "Unauthorized" }

      def self.on_load(app)
        app.before do |ctx|
          payload = ctx.get(:jwt_payload)
          unless payload
            status = options[:unauthorized_status]
            body = options[:unauthorized_body]
            ctx.response_status = status
            ctx.response_body = body
          end
        end
      end
    end
  end
end
