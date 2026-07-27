module RubyAPI
  module ErrorHandler
    def self.included(base)
      base.instance_variable_set(:@error_handlers, {})
    end

    def self.extended(base)
      base.instance_variable_set(:@error_handlers, {})
    end

    def rescue_from(exception_class, status: 500)
      @error_handlers ||= {}
      @error_handlers[exception_class] = status
    end

    def error_handlers
      @error_handlers || {}
    end
  end
end
