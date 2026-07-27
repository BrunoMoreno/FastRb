module RubyAPI
  class Config
    attr_accessor :environment, :settings

    def initialize
      @environment = ENV.fetch("FASTRB_ENV", "development")
      @settings = default_settings
    end

    def load_environment_config(app_root = Dir.pwd)
      config_file = File.join(app_root, "config", "environments", "#{@environment}.rb")
      return unless File.exist?(config_file)
      instance_eval(File.read(config_file))
    end

    def setting(key, value)
      @settings[key] = value
    end

    def get(key)
      @settings[key]
    end

    private

    def default_settings
      {
        port: 3000,
        host: "0.0.0.0",
        log_level: "info",
        secret_key: "change_me_in_production"
      }
    end
  end
end
