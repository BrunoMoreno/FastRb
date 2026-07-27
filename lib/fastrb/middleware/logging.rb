require "json"
require "time"

module RubyAPI
  module Middleware
    class StructuredLogger
      def initialize(app, output: $stdout)
        @app = app
        @output = output
      end

      def call(env)
        start_time = Time.now
        status, headers, body = @app.call(env)
        duration_ms = ((Time.now - start_time) * 1000).round(2)

        log_entry = {
          method: env["REQUEST_METHOD"],
          path: env["PATH_INFO"],
          status: status,
          duration_ms: duration_ms,
          timestamp: Time.now.iso8601
        }

        @output.puts(JSON.generate(log_entry))
        [status, headers, body]
      end
    end

    class Metrics
      attr_reader :counts, :latencies

      def initialize(app)
        @app = app
        @counts = Hash.new(0)
        @latencies = Hash.new(0.0)
        @mutex = Mutex.new
      end

      def call(env)
        start_time = Time.now
        status, headers, body = @app.call(env)
        duration = Time.now - start_time

        key = "#{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}"
        @mutex.synchronize do
          @counts[key] += 1
          @latencies[key] += duration
        end

        [status, headers, body]
      end

      def summary
        @mutex.synchronize do
          @counts.each_with_object({}) do |(key, count), hash|
            total = @latencies[key]
            hash[key] = {
              count: count,
              avg_latency_ms: (total / count * 1000).round(2)
            }
          end
        end
      end
    end
  end
end
