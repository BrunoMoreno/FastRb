module RubyAPI
  class Container
    def initialize
      @registrations = {}
      @instances = {}
    end

    def register(name, klass = nil, &block)
      @registrations[name] = block || -> { klass.new }
    end

    def resolve(name)
      return @instances[name] if @instances.key?(name)
      registration = @registrations[name]
      return nil unless registration
      @instances[name] = registration.call
    end

    def registered?(name)
      @registrations.key?(name)
    end
  end

  class DependencyError < StandardError; end

  module DI
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def inject(name)
        @injected_deps ||= []
        @injected_deps << name
      end

      def injected_deps
        @injected_deps || []
      end

      def depends(check_class, failure_status: 401)
        @dependency_checks ||= []
        @dependency_checks << { check: check_class, status: failure_status }
      end

      def dependency_checks
        @dependency_checks || []
      end
    end
  end
end
