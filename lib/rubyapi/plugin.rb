module RubyAPI
  class Plugin
    def self.inherited(subclass)
      RubyAPI::PluginRegistry.register(subclass)
    end

    def self.on_load(app); end
    def self.register_routes(app); end
    def self.register_cli(commands); end
    def self.plugin_name
      name.split("::").last
    end

    def self.options
      @options ||= {}
    end

    def self.option(key, value = nil)
      @options ||= {}
      @options[key] = value
    end
  end

  class PluginRegistry
    def self.plugins
      @plugins ||= []
    end

    def self.register(klass)
      plugins << klass unless plugins.include?(klass)
    end

    def self.find(name)
      plugins.find { |p| p.plugin_name == name.to_s || p == name }
    end
  end
end
