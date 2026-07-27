require "json"
require "rack"

module RubyAPI
  class Context
    attr_reader :request, :params, :body
    attr_accessor :response_body, :response_status, :response_headers

    def initialize(request, route)
      @request = request
      @route = route
      @params = extract_path_params
      @params.merge!(extract_query_params)
      @body = extract_body
      @response_headers = {}
    end

    def apply_param_types!
      type_map = @route[:params]
      type_map.each do |name, type|
        next unless @params.key?(name)
        @params[name] = RubyAPI::ParamConverters.convert(@params[name], type)
      end
    rescue RubyAPI::ConversionError => e
      @response_status = 422
      @response_body = { error: e.message }
    end

    private

    def extract_path_params
      pattern = @route[:pattern]
      names = @route[:param_names]
      match = pattern.match(@request.path_info)
      return {} unless match
      names.each_with_index.each_with_object({}) do |(name, idx), hash|
        hash[name] = match[idx + 1]
      end
    end

    def extract_query_params
      @request.params.each_with_object({}) do |(k, v), hash|
        hash[k.to_sym] = v
      end
    end

    def extract_body
      return nil unless @request.post? || @request.put? || @request.patch?
      return nil unless @request.content_type&.include?("application/json")

      body_raw = @request.body.read
      @request.body.rewind
      return {} if body_raw.empty?

      parsed = JSON.parse(body_raw)
      BodyProxy.new(parsed)
    rescue JSON::ParserError
      BodyProxy.new({})
    end
  end

  class BodyProxy
    def initialize(data)
      @data = data
    end

    def [](key)
      @data[key.to_s]
    end

    def method_missing(name, *args)
      if @data.key?(name.to_s)
        @data[name.to_s]
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      @data.key?(name.to_s) || super
    end
  end
end
