require_relative "lib/rubyapi/version"

Gem::Specification.new do |spec|
  spec.name          = "rubyapi"
  spec.version       = RubyAPI::VERSION
  spec.authors       = ["Bruno Queiroz"]
  spec.summary       = "A FastAPI-inspired web framework for Ruby"
  spec.description   = "RubyAPI is a modern web framework for Ruby, inspired by FastAPI, with optional typing, automatic validation, and OpenAPI documentation."
  spec.homepage      = "https://github.com/bruno/rubyapi"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.files         = Dir["lib/**/*", "bin/*"]
  spec.bindir        = "bin"
  spec.executables   = ["rubyapi"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rack", "~> 3.0"
  spec.add_dependency "bigdecimal", "~> 3.0"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rack-test", "~> 2.0"
end
