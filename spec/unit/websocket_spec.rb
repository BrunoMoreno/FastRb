require "rubyapi"

RSpec.describe RubyAPI::WebSocket do
  it "creates a WebSocket instance" do
    ws = RubyAPI::WebSocket.new({})
    expect(ws).to be_a(RubyAPI::WebSocket)
    expect(ws).not_to be_closed
  end

  it "sends and receives messages" do
    ws = RubyAPI::WebSocket.new({})
    ws.send("hello")
    msg = ws.receive
    expect(msg[:type]).to eq(:send)
    expect(msg[:data]).to eq("hello")
  end

  it "closes with code and reason" do
    ws = RubyAPI::WebSocket.new({})
    ws.close(1001, "normal")
    expect(ws).to be_closed
    msg = ws.receive
    expect(msg[:type]).to eq(:close)
    expect(msg[:code]).to eq(1001)
    expect(msg[:reason]).to eq("normal")
  end

  it "calls on_open handler" do
    opened = false
    ws = RubyAPI::WebSocket.new({})
    ws.on_open { |conn| opened = true }
    ws.process!
    expect(opened).to be true
  end

  it "calls on_close handler on completion" do
    closed = false
    ws = RubyAPI::WebSocket.new({})
    ws.on_close { |err| closed = true }
    ws.process!
    expect(closed).to be true
  end
end
