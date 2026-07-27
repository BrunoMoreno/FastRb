require "rubyapi"
require "stringio"

RSpec.describe RubyAPI::App do
  include Rack::Test::Methods

  def app
    RubyAPI::App.new do
      post "/upload" do |ctx|
        file = ctx.files["file"]
        { filename: file.filename, type: file.type, content: file.read }
      end

      get "/hello" do
        { message: "Hello" }
      end
    end
  end

  describe "file upload" do
    it "receives and parses multipart file" do
      file_content = "Hello, this is a test file"
      file = Rack::Test::UploadedFile.new(StringIO.new(file_content), "text/plain", false, original_filename: "test.txt")

      post "/upload", { "file" => file }, { "CONTENT_TYPE" => "multipart/form-data" }
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body["filename"]).to eq("test.txt")
      expect(body["type"]).to eq("text/plain")
      expect(body["content"]).to eq(file_content)
    end
  end
end
