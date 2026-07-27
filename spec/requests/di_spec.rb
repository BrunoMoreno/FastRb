require "rubyapi"

class CurrentUser
  def initialize
    @name = "John"
  end

  def call(ctx)
    true
  end

  def name
    @name
  end
end

class FailingAuth
  def call(ctx)
    false
  end
end

RSpec.describe RubyAPI::App do
  include Rack::Test::Methods

  describe "dependency injection" do
    def app
      app = RubyAPI::App.new do
        register(:current_user) { CurrentUser.new }

        get "/profile", inject: [:current_user] do |ctx|
          user = ctx.get(:current_user)
          { name: user.name }
        end
      end
      app
    end

    it "injects resolved dependency into context" do
      get "/profile"
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body["name"]).to eq("John")
    end
  end

  describe "depends with short-circuit" do
    def app
      app = RubyAPI::App.new do
        get "/protected", depends: [{ check: ->(ctx) { false }, status: 401 }] do |ctx|
          { secret: "data" }
        end

        get "/public" do |ctx|
          { public: true }
        end
      end
      app
    end

    it "returns 401 when depends check fails" do
      get "/protected"
      expect(last_response.status).to eq(401)
    end

    it "allows access when no depends check" do
      get "/public"
      expect(last_response.status).to eq(200)
    end
  end

  describe "depends with class" do
    def app
      app = RubyAPI::App.new do
        register(:auth) { FailingAuth.new }

        get "/secure", depends: [{ check: :auth, status: 403 }] do |ctx|
          { secure: true }
        end
      end
      app
    end

    it "returns custom status when class check fails" do
      get "/secure"
      expect(last_response.status).to eq(403)
    end
  end
end
