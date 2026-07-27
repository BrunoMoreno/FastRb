module RubyAPI
  module Serializer
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def field(name, type: String)
        @fields ||= {}
        @fields[name] = type
      end

      def fields
        @fields || {}
      end
    end

    def serialize(object)
      self.class.fields.each_with_object({}) do |(name, type), hash|
        value = object.send(name)
        hash[name] = value
      end
    end
  end
end
