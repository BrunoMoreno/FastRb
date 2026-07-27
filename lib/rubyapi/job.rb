module RubyAPI
  class Job
    class << self
      def inherited(subclass)
        subclass.instance_variable_set(:@queue, Queue.new)
        subclass.instance_variable_set(:@worker_thread, nil)
        subclass.instance_variable_set(:@job_results, [])
        subclass.instance_variable_set(:@job_errors, [])
        JobRegistry.register(subclass)
      end

      def enqueue(*args)
        job = { class: self, args: args, enqueued_at: Time.now }
        @queue << job
        start_worker unless @worker_thread&.alive?
        job
      end

      def results
        @job_results.dup
      end

      def errors
        @job_errors.dup
      end

      def clear_results
        @job_results.clear
        @job_errors.clear
      end

      def queue
        @queue
      end

      def perform(*args)
        raise "#{self} must implement `perform`"
      end

      def worker_running?
        @worker_thread&.alive? || false
      end

      private

      def start_worker
        @worker_thread = Thread.new do
          loop do
            break if @queue.empty? && !@worker_thread&.alive?
            begin
              job = @queue.pop(true)
            rescue ThreadError
              sleep 0.01
              retry
            end

            begin
              result = job[:class].perform(*job[:args])
              @job_results << {
                class: job[:class].name,
                args: job[:args],
                result: result,
                completed_at: Time.now
              }
            rescue => e
              @job_errors << {
                class: job[:class].name,
                args: job[:args],
                error: e.class.name,
                message: e.message,
                failed_at: Time.now
              }
            end
          end
        end
      end
    end
  end

  class JobRegistry
    def self.jobs
      @jobs ||= []
    end

    def self.register(klass)
      jobs << klass unless jobs.include?(klass)
    end

    def self.find(name)
      jobs.find { |j| j.name == name || j.name&.end_with?("::#{name}") }
    end
  end
end
