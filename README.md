# RubyAPI

A FastAPI-inspired web framework for Ruby, with optional typing, automatic validation, and OpenAPI documentation.

## Requirements

- Ruby 3.3+
- Rack-compatible server (Falcon recommended, Puma as fallback)

## Installation

    gem install rubyapi

Or add to your Gemfile:

    gem "rubyapi", "~> 0.1.0"

## Quick Start

Create a new project:

    rubyapi new myapp
    cd myapp
    bundle install
    rubyapi server

## Usage

```ruby
require "rubyapi"

app = RubyAPI::App.new do
  get "/hello" do
    { message: "Hello World" }
  end

  get "/users/:id", params: { id: Integer } do |ctx|
    { id: ctx.params[:id] }
  end

  post "/users" do |ctx|
    { created: true, name: ctx.body.name }
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
- **Type Conversion**: Automatic parameter conversion with 12 built-in types (String, Integer, Float, Boolean, Date, Time, DateTime, Array, Hash, UUID, Decimal, Symbol)
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

## Testing

    bundle exec rspec

## License

MIT
