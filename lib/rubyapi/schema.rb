module RubyAPI
  class Schema
    class ValidationError < StandardError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
        super("Validation failed: #{errors.map { |k, v| "#{k}: #{v}" }.join(', ')}")
      end
    end

    def self.field(name, type: String)
      @fields ||= {}
      @fields[name] = type
    end

    def self.fields
      @fields || {}
    end

    def self.inherited(subclass)
      subclass.instance_variable_set(:@fields, (@fields || {}).dup)
    end

    def self.validate(data)
      errors = {}
      result = {}

      fields.each do |name, type|
        value = data.is_a?(Hash) ? (data[name.to_s] || data[name]) : nil
        if value.nil?
          errors[name] = "is required"
          next
        end
        begin
          result[name] = ParamConverters.convert(value, type)
        rescue ConversionError => e
          errors[name] = e.message
        end
      end

      raise ValidationError.new(errors) if errors.any?
      result
    end
  end
end
