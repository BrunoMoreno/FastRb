require "securerandom"

module RubyAPI
  class StreamingBody
    include Enumerable

    def initialize
      @buffer = Queue.new
      @closed = false
    end

    def write(data)
      @buffer << data.to_s
    end

    def close
      @closed = true
      @buffer << nil
    end

    def each
      loop do
        data = @buffer.pop
        break if data.nil?
        yield data
      end
    end

    def closed?
      @closed
    end
  end

  class SSEStream
    attr_reader :body

    def initialize
      @body = StreamingBody.new
      @sse = SSE.new(@body)
      @closed = false
    end

    def send_event(event:, data:, id: nil)
      return if @closed
      @sse.send(event: event, data: data, id: id)
    end

    def close
      @closed = true
      @sse.close
      @body.close
    end

    def closed?
      @closed
    end
  end
end
