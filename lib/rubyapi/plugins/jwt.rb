require "json"
require "base64"
require "openssl"
require "jwt"

module RubyAPI
  module Plugins
    class JWT < Plugin
      option :secret, "default_secret"
      option :algorithm, "HS256"
      option :header, "Authorization"
      option :prefix, "Bearer "

      def self.decode(token)
        secret = options[:secret]
        algorithm = options[:algorithm]
        payload, _header = ::JWT.decode(token, secret, true, algorithm: algorithm)
        payload
      rescue StandardError
        nil
      end

      def self.encode(payload)
        secret = options[:secret]
        algorithm = options[:algorithm]
        ::JWT.encode(payload, secret, algorithm)
      end

      def self.on_load(app)
        app.before do |ctx|
          header_value = ctx.request.get_header("HTTP_AUTHORIZATION")
          next unless header_value

          prefix = options[:prefix]
          token = header_value.sub(/\A#{Regexp.escape(prefix)}/, "")
          payload = decode(token)
          ctx.set(:jwt_payload, payload) if payload
        end
      end
    end
  end
end
