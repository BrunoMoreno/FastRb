require "rubyapi"
require "stringio"

RSpec.describe RubyAPI::Middleware::StructuredLogger do
  include Rack::Test::Methods

  def app
    @log_output = StringIO.new
    inner = RubyAPI::App.new do
      get "/hello" do
        { message: "Hello" }
      end
    end
    RubyAPI::Middleware::StructuredLogger.new(inner, output: @log_output)
  end

  it "logs request in JSON format" do
    get "/hello"
    @log_output.rewind
    log_line = @log_output.gets
    log = JSON.parse(log_line)

    expect(log["method"]).to eq("GET")
    expect(log["path"]).to eq("/hello")
    expect(log["status"]).to eq(200)
    expect(log["duration_ms"]).to be_a(Numeric)
    expect(log["timestamp"]).not_to be_nil
  end
end

RSpec.describe RubyAPI::Middleware::Metrics do
  include Rack::Test::Methods

  def app
    inner = RubyAPI::App.new do
      get "/hello" do
        { message: "Hello" }
      end

      get "/slow" do
        { message: "Slow" }
      end
    end
    @metrics = RubyAPI::Middleware::Metrics.new(inner)
    @metrics
  end

  it "tracks request counts" do
    3.times { get "/hello" }
    2.times { get "/slow" }

    summary = @metrics.summary
    expect(summary["GET /hello"][:count]).to eq(3)
    expect(summary["GET /slow"][:count]).to eq(2)
  end

  it "tracks average latency" do
    5.times { get "/hello" }
    summary = @metrics.summary
    expect(summary["GET /hello"][:avg_latency_ms]).to be >= 0
  end
end
