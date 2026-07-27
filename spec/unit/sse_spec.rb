require "fastrb"
require "stringio"

RSpec.describe RubyAPI::SSE do
  it "writes SSE formatted events" do
    output = StringIO.new
    sse = RubyAPI::SSE.new(output)
    sse.send(event: "message", data: "hello", id: "1")

    output.rewind
    content = output.read
    expect(content).to include("event: message")
    expect(content).to include("data: hello")
    expect(content).to include("id: 1")
  end

  it "writes data without event or id" do
    output = StringIO.new
    sse = RubyAPI::SSE.new(output)
    sse.send(event: nil, data: "plain data")

    output.rewind
    content = output.read
    expect(content).to include("data: plain data")
    expect(content).not_to include("event:")
    expect(content).not_to include("id:")
  end

  it "handles multiline data" do
    output = StringIO.new
    sse = RubyAPI::SSE.new(output)
    sse.send(event: "test", data: "line1\nline2")

    output.rewind
    content = output.read
    expect(content).to include("data: line1\n")
    expect(content).to include("data: line2\n")
  end

  it "closes the stream" do
    output = StringIO.new
    sse = RubyAPI::SSE.new(output)
    expect(sse).not_to be_closed
    sse.close
    expect(sse).to be_closed
  end
end

RSpec.describe RubyAPI::StreamingBody do
  it "writes and reads data" do
    body = RubyAPI::StreamingBody.new
    Thread.new do
      body.write("chunk1")
      body.write("chunk2")
      body.close
    end

    chunks = []
    body.each { |c| chunks << c }
    expect(chunks).to eq(["chunk1", "chunk2"])
  end

  it "closes properly" do
    body = RubyAPI::StreamingBody.new
    expect(body).not_to be_closed
    body.close
    expect(body).to be_closed
  end
end
