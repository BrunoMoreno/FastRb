require "rubyapi"

RSpec.describe RubyAPI::Plugins::CORS do
  include Rack::Test::Methods

  def app
    RubyAPI::App.new do
      plugin RubyAPI::Plugins::CORS, origins: ["https://example.com"]

      get "/hello" do |ctx|
        { message: "Hello" }
      end
    end
  end

  it "adds CORS headers for allowed origin" do
    get "/hello", nil, { "HTTP_ORIGIN" => "https://example.com" }
    expect(last_response.headers["access-control-allow-origin"]).to eq("https://example.com")
  end

  it "does not add CORS headers for disallowed origin" do
    get "/hello", nil, { "HTTP_ORIGIN" => "https://evil.com" }
    expect(last_response.headers["access-control-allow-origin"]).to be_nil
  end

  it "returns 204 for OPTIONS preflight" do
    options "/hello", nil, { "HTTP_ORIGIN" => "https://example.com" }
    expect(last_response.status).to eq(204)
  end
end

RSpec.describe RubyAPI::Plugins::JWT do
  include Rack::Test::Methods

  def app
    RubyAPI::App.new do
      plugin RubyAPI::Plugins::JWT, secret: "test_secret"

      get "/protected" do |ctx|
        payload = ctx.get(:jwt_payload)
        if payload
          { user_id: payload["user_id"] }
        else
          { error: "no token" }
        end
      end
    end
  end

  it "decodes valid JWT token" do
    app
    token = RubyAPI::Plugins::JWT.encode({ "user_id" => 42 })
    get "/protected", nil, { "HTTP_AUTHORIZATION" => "Bearer #{token}" }
    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body["user_id"]).to eq(42)
  end

  it "ignores invalid token" do
    get "/protected", nil, { "HTTP_AUTHORIZATION" => "Bearer invalid_token" }
    body = JSON.parse(last_response.body)
    expect(body["error"]).to eq("no token")
  end
end

RSpec.describe RubyAPI::Plugins::Auth do
  include Rack::Test::Methods

  def app
    RubyAPI::App.new do
      plugin RubyAPI::Plugins::JWT, secret: "test_secret"
      plugin RubyAPI::Plugins::Auth

      get "/secret" do |ctx|
        { secret: "data" }
      end
    end
  end

  it "returns 401 when no JWT token" do
    get "/secret"
    expect(last_response.status).to eq(401)
  end

  it "allows access with valid token" do
    app
    token = RubyAPI::Plugins::JWT.encode({ "user_id" => 1 })
    get "/secret", nil, { "HTTP_AUTHORIZATION" => "Bearer #{token}" }
    expect(last_response.status).to eq(200)
  end
end

RSpec.describe RubyAPI::Plugins::Cache do
  include Rack::Test::Methods

  before { RubyAPI::Plugins::Cache.clear }

  def app
    RubyAPI::App.new do
      plugin RubyAPI::Plugins::Cache, default_ttl: 60

      get "/cached" do |ctx|
        cache = ctx.get(:cache)
        cached = cache.get("test_key")
        if cached
          { from_cache: true, value: cached }
        else
          cache.set("test_key", "hello")
          { from_cache: false }
        end
      end
    end
  end

  it "caches values" do
    get "/cached"
    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body["from_cache"]).to eq(false)

    get "/cached"
    body = JSON.parse(last_response.body)
    expect(body["from_cache"]).to eq(true)
    expect(body["value"]).to eq("hello")
  end
end
