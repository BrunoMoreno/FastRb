require "fastrb"

RSpec.describe RubyAPI::App do
  include Rack::Test::Methods

  def app
    RubyAPI::App.new do
      get "/hello" do |_ctx|
        { message: "Hello World" }
      end

      get "/users/:id" do |ctx|
        { id: ctx.params[:id] }
      end

      post "/users" do |ctx|
        { created: true, name: ctx.body.name }
      end

      group "/api" do
        group "/v1" do
          get "/users" do |_ctx|
            { users: [] }
          end
        end
      end

      get "/typed/:id", params: { id: Integer } do |ctx|
        { id: ctx.params[:id] }
      end
    end
  end

  describe "GET /hello" do
    it "returns JSON message" do
      get "/hello"
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq("message" => "Hello World")
    end
  end

  describe "GET /users/:id" do
    it "extracts path param" do
      get "/users/42"
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq("id" => "42")
    end
  end

  describe "POST /users" do
    it "parses JSON body" do
      post "/users", '{"name":"John"}', { "CONTENT_TYPE" => "application/json" }
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body["name"]).to eq("John")
    end
  end

  describe "group routing" do
    it "resolves nested group prefix" do
      get "/api/v1/users"
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq("users" => [])
    end
  end

  describe "type conversion" do
    it "converts param to Integer" do
      get "/typed/123"
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)["id"]).to eq(123)
    end

    it "returns 422 for invalid type" do
      get "/typed/abc"
      expect(last_response.status).to eq(422)
    end
  end

  describe "404" do
    it "returns 404 for unknown routes" do
      get "/nonexistent"
      expect(last_response.status).to eq(404)
    end
  end

  describe "OpenAPI" do
    it "serves /openapi.json" do
      get "/openapi.json"
      expect(last_response.status).to eq(200)
      spec = JSON.parse(last_response.body)
      expect(spec["openapi"]).to eq("3.0.0")
      expect(spec["paths"]).to have_key("/hello")
    end
  end

  describe "Swagger UI" do
    it "serves /docs" do
      get "/docs"
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include("swagger-ui")
    end
  end
end
