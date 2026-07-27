require "fastrb"

RSpec.describe RubyAPI::Config do
  subject(:config) { described_class.new }

  describe "#environment" do
    it "defaults to development" do
      expect(config.environment).to eq("development")
    end

    it "reads from FASTRB_ENV" do
      ENV["FASTRB_ENV"] = "test"
      config = described_class.new
      expect(config.environment).to eq("test")
    ensure
      ENV.delete("FASTRB_ENV")
    end
  end

  describe "#settings" do
    it "has default settings" do
      expect(config.get(:port)).to eq(3000)
      expect(config.get(:host)).to eq("0.0.0.0")
    end

    it "allows setting custom values" do
      config.setting(:port, 8080)
      expect(config.get(:port)).to eq(8080)
    end
  end

  describe "#load_environment_config" do
    it "loads config file for current environment" do
      Dir.mktmpdir do |dir|
        config_dir = File.join(dir, "config", "environments")
        FileUtils.mkdir_p(config_dir)
        File.write(File.join(config_dir, "test.rb"), 'setting :port, 9999')

        config = described_class.new
        config.environment = "test"
        config.load_environment_config(dir)
        expect(config.get(:port)).to eq(9999)
      end
    end

    it "does not fail if config file does not exist" do
      expect { config.load_environment_config("/nonexistent") }.not_to raise_error
    end
  end
end
