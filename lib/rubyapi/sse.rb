module RubyAPI
  class SSE
    attr_reader :io

    def initialize(io)
      @io = io
      @closed = false
    end

    def send(event:, data:, id: nil)
      return if @closed
      @io.write("event: #{event}\n") if event
      @io.write("id: #{id}\n") if id
      data.to_s.each_line do |line|
        @io.write("data: #{line}")
      end
      @io.write("\n")
      @io.flush
    end

    def close
      @closed = true
      @io.close if @io.respond_to?(:close) && !@io.closed?
    end

    def closed?
      @closed
    end
  end
end
