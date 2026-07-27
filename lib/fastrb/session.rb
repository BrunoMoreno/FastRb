require "rack"
require "json"
require "base64"
require "openssl"

module RubyAPI
  class Session
    SESSION_COOKIE = "_fastrb_session".freeze

    def initialize(request, secret_key: nil)
      @request = request
      @secret_key = secret_key || "fastrb_default_secret"
      @data = load_session
    end

    def [](key)
      @data[key.to_s]
    end

    def []=(key, value)
      @data[key.to_s] = value
    end

    def to_hash
      @data.dup
    end

    def serialize
      json = JSON.generate(@data)
      encode(json)
    end

    private

    def load_session
      cookie_value = @request.cookies[SESSION_COOKIE]
      return {} unless cookie_value
      json = decode(cookie_value)
      JSON.parse(json)
    rescue StandardError
      {}
    end

    def encode(data)
      encoded = Base64.strict_encode64(data)
      signature = sign(encoded)
      "#{encoded}.#{signature}"
    end

    def decode(data)
      encoded, signature = data.to_s.split(".", 2)
      return nil unless encoded && signature
      expected = sign(encoded)
      return nil unless Rack::Utils.secure_compare(signature, expected)
      Base64.strict_decode64(encoded)
    end

    def sign(data)
      OpenSSL::HMAC.hexdigest("SHA256", @secret_key, data)
    end
  end
end
