require "json"
require "rack"

module RubyAPI
  class Context
    attr_reader :request, :params, :body, :session, :files
    attr_accessor :response_body, :response_status, :response_headers

    def initialize(request, route)
      @request = request
      @route = route
      @params = extract_path_params
      @params.merge!(extract_query_params)
      @body = extract_body
      @files = extract_files
      @session = {}
      @response_headers = {}
    end

    def session=(val)
      @session = val
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

    def validate_body!(schema_class)
      raw = @body ? (@body.is_a?(BodyProxy) ? @body.to_h : @body) : {}
      validated = schema_class.validate(raw)
      stringified = validated.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
      @body = BodyProxy.new(stringified)
    rescue Schema::ValidationError => e
      @response_status = 422
      @response_body = { errors: e.errors }
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

    def extract_files
      return {} unless @request.content_type&.include?("multipart/form-data")

      files = {}
      params = @request.env["rack.request.form_hash"]
      return files unless params.is_a?(Hash)

      params.each do |name, info|
        next unless info.is_a?(Hash) && info[:tempfile]
        files[name] = UploadedFile.new(
          filename: info[:filename],
          type: info[:type],
          tempfile: info[:tempfile]
        )
      end
      files
    end
  end

  class BodyProxy
    def initialize(data)
      @data = data
    end

    def [](key)
      @data[key.to_s]
    end

    def to_h
      @data
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

  class UploadedFile
    attr_reader :filename, :type, :tempfile

    def initialize(filename:, type:, tempfile:)
      @filename = filename
      @type = type
      @tempfile = tempfile
    end

    def read
      @tempfile.read
    end

    def rewind
      @tempfile.rewind
    end
  end
end
