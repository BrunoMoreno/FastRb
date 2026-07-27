require "fastrb"

RSpec.describe RubyAPI::App do
  include Rack::Test::Methods

  def app
    RubyAPI::App.new do
      post "/login" do |ctx|
        ctx.session[:user_id] = 42
        { logged_in: true }
      end

      get "/profile" do |ctx|
        { user_id: ctx.session[:user_id] }
      end

      get "/hello" do
        { message: "Hello" }
      end
    end
  end

  describe "session persistence" do
    it "persists session data between requests" do
      post "/login", '{"username":"john"}', { "CONTENT_TYPE" => "application/json" }
      expect(last_response.status).to eq(200)

      cookie = last_response.headers["set-cookie"]
      expect(cookie).to include("_fastrb_session=")

      get "/profile", nil, { "HTTP_COOKIE" => cookie.split(";").first }
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body["user_id"]).to eq(42)
    end

    it "returns nil for unset session values" do
      get "/hello"
      get "/profile"
      body = JSON.parse(last_response.body)
      expect(body["user_id"]).to be_nil
    end
  end
end
