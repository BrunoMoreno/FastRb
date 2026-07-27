# RubyAPI

A FastAPI-inspired web framework for Ruby, with optional typing, automatic validation, and OpenAPI documentation.

## Requirements

- Ruby 3.3+
- Rack-compatible server (Falcon recommended, Puma as fallback)

## Installation

    gem install rubyapi

Or add to your Gemfile:

    gem "rubyapi", "~> 0.2.0"

## Quick Start

Create a new project:

    rubyapi new myapp
    cd myapp
    bundle install
    rubyapi server

## Usage

```ruby
require "rubyapi"

class UserSchema < RubyAPI::Schema
  field :name, type: String
  field :age, type: Integer
end

app = RubyAPI::App.new do
  get "/hello" do
    { message: "Hello World" }
  end

  get "/users/:id", params: { id: Integer } do |ctx|
    { id: ctx.params[:id] }
  end

  post "/users", body: UserSchema do |ctx|
    { created: true, name: ctx.body.name, age: ctx.body.age }
  end

  group "/api" do
    group "/v1" do
      get "/users" do
        { users: [] }
      end
    end
  end
end

run app
```

## Features

- **Routing**: Trie-based O(1) routing with support for path params, groups, and all HTTP methods
- **Type Conversion**: Automatic parameter conversion with 12 built-in types
- **Schemas**: Declarative body validation with `field :name, Type` DSL
- **File Uploads**: Multipart/form-data support with automatic file extraction
- **Sessions**: Cookie-based signed sessions for request persistence
- **Error Handling**: `rescue_from` mapping exceptions to HTTP status codes
- **Environment Config**: Per-environment configuration via `config/environments/`
- **JSON Serialization**: Automatic Hash/Array to JSON response serialization
- **Middleware**: Rack-compatible middleware support via `use`
- **Hooks**: Global and route-scoped `before`/`after` hooks
- **OpenAPI**: Automatic OpenAPI documentation at `/openapi.json` with Swagger UI at `/docs`

## Supported Types

| Type | Example |
|------|---------|
| String | `"hello"` |
| Integer | `42` |
| Float | `3.14` |
| Boolean | `true` / `false` |
| Date | `2026-01-15` |
| Time | `2026-01-15T10:30:00Z` |
| DateTime | `2026-01-15T10:30:00` |
| Array | `[1, 2, 3]` |
| Hash | `{"key": "value"}` |
| UUID | `550e8400-e29b-41d4-a716-446655440000` |
| Decimal | `3.14` |
| Symbol | `:hello` |

## Configuration

Set the environment via `RUBYAPI_ENV`:

    RUBYAPI_ENV=production rubyapi server

Create environment-specific config in `config/environments/`:

```ruby
# config/environments/production.rb
setting :port, 80
setting :secret_key, ENV["SECRET_KEY"]
```

## Testing

    bundle exec rspec

## License

MIT
