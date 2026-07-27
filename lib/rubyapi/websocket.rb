module RubyAPI
  class WebSocket
    attr_reader :env, :path

    def initialize(env, &handler)
      @env = env
      @handler = handler
      @messages = Queue.new
      @closed = false
      @on_message = nil
      @on_close = nil
      @on_open = nil
    end

    def on_open(&block)
      @on_open = block
    end

    def on_message(&block)
      @on_message = block
    end

    def on_close(&block)
      @on_close = block
    end

    def send(data)
      @messages << { type: :send, data: data }
    end

    def close(code = 1000, reason = "")
      @messages << { type: :close, code: code, reason: reason }
      @closed = true
    end

    def closed?
      @closed
    end

    def receive
      msg = @messages.pop
      msg
    end

    def hijack?
      true
    end

    def process!
      @on_open&.call(self)
      @handler.call(self) if @handler
    rescue => e
      @on_close&.call(e) if @on_close
    ensure
      @on_close&.call(nil) unless @closed
    end

    def self.upgrade(env)
      io = env["rack.hijack"]&.call
      return nil unless io
      io
    end
  end
end
