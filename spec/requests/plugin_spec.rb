require "rubyapi"

class TestPlugin < RubyAPI::Plugin
  option :greeting, "Hello"

  def self.on_load(app)
    app.get "/plugin-route" do |ctx|
      { from_plugin: true, greeting: options[:greeting] }
    end
  end
end

RSpec.describe RubyAPI::Plugin do
  describe "plugin registry" do
    it "registers plugin on inheritance" do
      expect(RubyAPI::PluginRegistry.plugins).to include(TestPlugin)
    end

    it "finds plugin by name" do
      found = RubyAPI::PluginRegistry.find("TestPlugin")
      expect(found).to eq(TestPlugin)
    end
  end
end

RSpec.describe RubyAPI::App do
  include Rack::Test::Methods

  describe "plugin registration" do
    def app
      app = RubyAPI::App.new do
        plugin TestPlugin, greeting: "Hi"
      end
      app
    end

    it "makes plugin routes available" do
      get "/plugin-route"
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body["from_plugin"]).to eq(true)
      expect(body["greeting"]).to eq("Hi")
    end
  end
end
