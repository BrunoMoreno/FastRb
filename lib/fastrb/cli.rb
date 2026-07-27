require "fileutils"
require_relative "version"

module RubyAPI
  class CLI
    def self.invoke(args)
      command = args[0]
      name = args[1]

      case command
      when "new"
        new_project(name)
      when "server"
        start_server
      when "version"
        puts "fastrb #{VERSION}"
      else
        puts "Usage: fastrb <command> [options]"
        puts ""
        puts "Commands:"
        puts "  new <name>    Create a new FastRb project"
        puts "  server        Start the server (Falcon/Puma)"
        puts "  version       Show version"
        exit 1
      end
    end

    def self.new_project(name)
      puts "Creating new FastRb project: #{name}"

      FileUtils.mkdir_p(name)
      FileUtils.mkdir_p("#{name}/app")
      FileUtils.mkdir_p("#{name}/config/environments")
      FileUtils.mkdir_p("#{name}/public")
      FileUtils.mkdir_p("#{name}/spec/unit")
      FileUtils.mkdir_p("#{name}/spec/requests")

      File.write("#{name}/Gemfile", gemfile_content(name))
      File.write("#{name}/config.ru", config_ru_content)
      File.write("#{name}/app/main.rb", main_rb_content)
      File.write("#{name}/app/routes.rb", routes_rb_content)
      File.write("#{name}/.rspec", ".rspec")
      File.write("#{name}/spec/spec_helper.rb", spec_helper_content)
      File.write("#{name}/spec/requests/hello_spec.rb", hello_spec_content)
      File.write("#{name}/README.md", readme_content(name))

      puts "Done! cd #{name} && bundle install && fastrb server"
    end

    def self.start_server
      require "rackup"
      rackup_file = File.join(Dir.pwd, "config.ru")
      unless File.exist?(rackup_file)
        puts "Error: config.ru not found in current directory"
        exit 1
      end
      Rackup::Server.start(config: rackup_file, Host: "0.0.0.0", Port: 3000)
    end

    private

    def self.gemfile_content(name)
      <<~GEMFILE
        source "https://rubygems.org"

        gem "fastrb", "~> #{RubyAPI::VERSION}"
        gem "rackup"
        gem "puma"
      GEMFILE
    end

    def self.config_ru_content
      <<~RUBY
        require_relative "app/main"
        require_relative "app/routes"

        run App.new
      RUBY
    end

    def self.main_rb_content
      <<~RUBY
        require "fastrb"

        class App < RubyAPI::App
          def initialize
            super do
              Routes.apply(self)
            end
          end
        end
      RUBY
    end

    def self.routes_rb_content
      <<~RUBY
        module Routes
          def self.apply(app)
            app.get "/hello" do
              { message: "Hello World" }
            end
          end
        end
      RUBY
    end

    def self.spec_helper_content
      <<~RUBY
        require "fastrb"
        require "rack/test"

        RSpec.configure do |config|
          config.expect_with :rspec do |expectations|
            expectations.include_chain_clauses_in_custom_matcher_descriptions = true
          end

          config.mock_with :rspec do |mocks|
            mocks.verify_partial_doubles = true
          end
        end
      RUBY
    end

    def self.hello_spec_content
      <<~RUBY
        require "spec_helper"

        RSpec.describe "GET /hello" do
          include Rack::Test::Methods

          def app
            App.new
          end

          it "returns hello world" do
            get "/hello"
            expect(last_response.status).to eq(200)
            expect(JSON.parse(last_response.body)["message"]).to eq("Hello World")
          end
        end
      RUBY
    end

    def self.readme_content(name)
      <<~MARKDOWN
        # #{name}

        A FastRb application.

        ## Setup

            bundle install

        ## Running

            fastrb server

        ## Testing

            bundle exec rspec
      MARKDOWN
    end
  end
end
