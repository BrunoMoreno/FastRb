require "fastrb"

RSpec.describe RubyAPI::Schema do
  class UserSchema < RubyAPI::Schema
    field :name, type: String
    field :age, type: Integer
  end

  class PostSchema < RubyAPI::Schema
    field :title, type: String
    field :body, type: String
    field :published, type: RubyAPI::Boolean
  end

  describe ".validate" do
    it "validates and converts valid data" do
      result = UserSchema.validate({ "name" => "John", "age" => "30" })
      expect(result[:name]).to eq("John")
      expect(result[:age]).to eq(30)
    end

    it "raises ValidationError for missing required fields" do
      expect {
        UserSchema.validate({ "name" => "John" })
      }.to raise_error(RubyAPI::Schema::ValidationError) do |e|
        expect(e.errors[:age]).to eq("is required")
      end
    end

    it "raises ValidationError for wrong type" do
      expect {
        UserSchema.validate({ "name" => "John", "age" => "not_a_number" })
      }.to raise_error(RubyAPI::Schema::ValidationError) do |e|
        expect(e.errors[:age]).to include("must be Integer")
      end
    end

    it "validates multiple fields correctly" do
      result = PostSchema.validate({
        "title" => "Hello",
        "body" => "World",
        "published" => "true"
      })
      expect(result[:title]).to eq("Hello")
      expect(result[:body]).to eq("World")
      expect(result[:published]).to eq(true)
    end

    it "collects all errors at once" do
      expect {
        UserSchema.validate({})
      }.to raise_error(RubyAPI::Schema::ValidationError) do |e|
        expect(e.errors.size).to eq(2)
      end
    end
  end
end

RSpec.describe RubyAPI::App do
  include Rack::Test::Methods

  class TestSchema < RubyAPI::Schema
    field :name, type: String
    field :age, type: Integer
  end

  def app
    RubyAPI::App.new do
      post "/users", body: TestSchema do |ctx|
        { created: true, name: ctx.body.name, age: ctx.body.age }
      end

      get "/hello" do
        { message: "Hello World" }
      end
    end
  end

  describe "schema validation" do
    it "validates body against schema and returns typed data" do
      post "/users", '{"name":"John","age":"30"}', { "CONTENT_TYPE" => "application/json" }
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body["name"]).to eq("John")
      expect(body["age"]).to eq(30)
    end

    it "returns 422 for invalid schema" do
      post "/users", '{"name":"John"}', { "CONTENT_TYPE" => "application/json" }
      expect(last_response.status).to eq(422)
      body = JSON.parse(last_response.body)
      expect(body["errors"]).to have_key("age")
    end

    it "returns 422 for wrong type" do
      post "/users", '{"name":"John","age":"not_a_number"}', { "CONTENT_TYPE" => "application/json" }
      expect(last_response.status).to eq(422)
    end
  end
end
