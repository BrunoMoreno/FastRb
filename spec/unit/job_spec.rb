require "rubyapi"

class TestJob < RubyAPI::Job
  def self.perform(name)
    "hello #{name}"
  end
end

class FailingJob < RubyAPI::Job
  def self.perform
    raise RuntimeError, "intentional failure"
  end
end

RSpec.describe RubyAPI::Job do
  before do
    TestJob.clear_results
    FailingJob.clear_results
  end

  it "enqueues and executes a job" do
    TestJob.enqueue("world")
    sleep 0.1
    expect(TestJob.results.length).to eq(1)
    expect(TestJob.results.first[:result]).to eq("hello world")
  end

  it "records errors from failing jobs" do
    FailingJob.enqueue
    sleep 0.1
    expect(FailingJob.errors.length).to eq(1)
    expect(FailingJob.errors.first[:error]).to eq("RuntimeError")
    expect(FailingJob.errors.first[:message]).to eq("intentional failure")
  end

  it "returns the job definition from enqueue" do
    job = TestJob.enqueue("test")
    expect(job[:class]).to eq(TestJob)
    expect(job[:args]).to eq(["test"])
    expect(job[:enqueued_at]).to be_a(Time)
  end

  it "records error when perform is not defined" do
    klass = Class.new(RubyAPI::Job)
    klass.enqueue("test")
    sleep 0.1
    expect(klass.errors.length).to eq(1)
    expect(klass.errors.first[:message]).to include("must implement")
  end
end

RSpec.describe RubyAPI::JobRegistry do
  it "registers job classes" do
    expect(RubyAPI::JobRegistry.jobs).to include(TestJob)
  end

  it "finds jobs by name" do
    expect(RubyAPI::JobRegistry.find("TestJob")).to eq(TestJob)
  end
end
