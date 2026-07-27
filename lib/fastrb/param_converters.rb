require "securerandom"
require "time"
require "date"
require "bigdecimal"

module RubyAPI
  Boolean = Class.new unless defined?(Boolean)
  UUID = Class.new unless defined?(UUID)
  Decimal = BigDecimal unless defined?(Decimal)

  class ConversionError < StandardError
    def initialize(param_name, type_name)
      super("#{param_name} must be #{type_name}")
    end
  end

  module ParamConverters
    CONVERTERS = {
      String   => ->(v) { v.to_s },
      Integer  => ->(v) { Integer(v) },
      Float    => ->(v) { Float(v) },
      Boolean  => ->(v) {
        case v.to_s.downcase
        when "true", "1", "yes" then true
        when "false", "0", "no", "nil" then false
        else raise ArgumentError
        end
      },
      Date     => ->(v) { Date.parse(v) },
      Time     => ->(v) { Time.parse(v) },
      DateTime => ->(v) { DateTime.parse(v) },
      Array    => ->(v) {
        return v if v.is_a?(Array)
        JSON.parse(v)
      },
      Hash     => ->(v) {
        return v if v.is_a?(Hash)
        JSON.parse(v)
      },
      UUID     => ->(v) {
        uuid = v.to_s
        raise ArgumentError unless uuid.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
        uuid
      },
      Decimal  => ->(v) { BigDecimal(v.to_s) },
      Symbol   => ->(v) { v.to_sym }
    }.freeze

    def self.convert(value, type)
      converter = CONVERTERS[type]
      return value.to_s unless converter
      converter.call(value)
    rescue ArgumentError, TypeError, JSON::ParserError
      type_name = type.respond_to?(:name) ? type.name : type.to_s
      raise ConversionError.new(value.to_s, type_name)
    end
  end
end
