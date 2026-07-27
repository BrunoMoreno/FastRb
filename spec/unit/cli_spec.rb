require "fastrb/cli"
require "fileutils"
require "tmpdir"

RSpec.describe RubyAPI::CLI do
  let(:tmpdir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(tmpdir) }

  describe ".new_project" do
    before { described_class.new_project("#{tmpdir}/testapp") }

    it "creates the project directory" do
      expect(Dir.exist?("#{tmpdir}/testapp")).to be true
    end

    it "creates app/ directory" do
      expect(Dir.exist?("#{tmpdir}/testapp/app")).to be true
    end

    it "creates config/ directory" do
      expect(Dir.exist?("#{tmpdir}/testapp/config")).to be true
    end

    it "creates public/ directory" do
      expect(Dir.exist?("#{tmpdir}/testapp/public")).to be true
    end

    it "creates spec/ directory" do
      expect(Dir.exist?("#{tmpdir}/testapp/spec")).to be true
    end

    it "creates Gemfile" do
      expect(File.exist?("#{tmpdir}/testapp/Gemfile")).to be true
    end

    it "creates config.ru" do
      expect(File.exist?("#{tmpdir}/testapp/config.ru")).to be true
    end

    it "creates app/main.rb" do
      expect(File.exist?("#{tmpdir}/testapp/app/main.rb")).to be true
    end

    it "creates app/routes.rb" do
      expect(File.exist?("#{tmpdir}/testapp/app/routes.rb")).to be true
    end

    it "creates .rspec" do
      expect(File.exist?("#{tmpdir}/testapp/.rspec")).to be true
    end

    it "creates spec/spec_helper.rb" do
      expect(File.exist?("#{tmpdir}/testapp/spec/spec_helper.rb")).to be true
    end

    it "creates spec/requests/hello_spec.rb" do
      expect(File.exist?("#{tmpdir}/testapp/spec/requests/hello_spec.rb")).to be true
    end

    it "creates README.md" do
      expect(File.exist?("#{tmpdir}/testapp/README.md")).to be true
    end

    it "creates config/environments directory" do
      expect(Dir.exist?("#{tmpdir}/testapp/config/environments")).to be true
    end
  end
end
