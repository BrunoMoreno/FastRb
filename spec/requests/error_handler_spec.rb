require "rubyapi"

class CustomError < StandardError; end
class AnotherError < StandardError; end

RSpec.describe RubyAPI::App do
  include Rack::Test::Methods

  def app
    app = RubyAPI::App.new do
      get "/error" do
        raise CustomError, "something went wrong"
      end

      get "/another_error" do
        raise AnotherError, "another problem"
      end

      get "/hello" do
        { message: "Hello" }
      end

      rescue_from CustomError, status: 404
      rescue_from AnotherError, status: 422
    end
    app
  end

  describe "rescue_from" do
    it "maps CustomError to 404" do
      get "/error"
      expect(last_response.status).to eq(404)
      body = JSON.parse(last_response.body)
      expect(body["error"]).to eq("CustomError")
      expect(body["message"]).to eq("something went wrong")
    end

    it "maps AnotherError to 422" do
      get "/another_error"
      expect(last_response.status).to eq(422)
      body = JSON.parse(last_response.body)
      expect(body["error"]).to eq("AnotherError")
    end

    it "does not catch unrelated errors" do
      expect {
        app.call(Rack::MockRequest.env_for("/error"))
      }.not_to raise_error
    end
  end
end
