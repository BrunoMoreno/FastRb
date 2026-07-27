# FastRb

**A FastAPI-inspired micro web framework for Ruby** — optional parameter typing, automatic payload validation, dependency injection, a plugin system, and auto-generated OpenAPI documentation.

```ruby
require "fastrb"

app = RubyAPI::App.new do
  get "/hello/:name", params: { name: String } do |ctx|
    { message: "Hello, #{ctx.params[:name]}!" }
  end
end

run app
```

> **Project status:** FastRb is at version `0.2.x` and is an experimental, actively developed framework. The API may change between minor versions. It's great for prototyping, internal APIs, and studying framework architecture — evaluate carefully before using it in production (see [Known limitations](#known-limitations)).

---

## Table of contents

- [Why FastRb](#why-fastrb)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Core concepts](#core-concepts)
  - [The `App` DSL](#the-app-dsl)
  - [Routes and path parameters](#routes-and-path-parameters)
  - [Typing and automatic conversion](#typing-and-automatic-conversion)
  - [Body validation with `Schema`](#body-validation-with-schema)
  - [Route groups](#route-groups)
  - [`before` / `after` hooks](#before--after-hooks)
  - [Rack middleware](#rack-middleware)
  - [Dependency injection](#dependency-injection)
  - [Access control with `depends`](#access-control-with-depends)
  - [Sessions](#sessions)
  - [File uploads](#file-uploads)
  - [Error handling](#error-handling)
  - [Official plugins](#official-plugins)
  - [Structured logging and metrics](#structured-logging-and-metrics)
  - [WebSockets](#websockets)
  - [Server-Sent Events](#server-sent-events)
  - [HTTP streaming](#http-streaming)
  - [Background jobs](#background-jobs)
  - [OpenAPI and Swagger UI](#openapi-and-swagger-ui)
- [Supported types](#supported-types)
- [Per-environment configuration](#per-environment-configuration)
- [CLI](#cli)
- [Generated project structure](#generated-project-structure)
- [Testing](#testing)
- [Known limitations](#known-limitations)
- [Contributing](#contributing)
- [License](#license)

---

## Why FastRb

FastRb brings to the Ruby ecosystem an API development style popularized by FastAPI (Python): declare routes with short blocks, annotate types for automatic conversion/validation, and get OpenAPI documentation "for free" straight from your routes — without relying on a full-stack framework like Rails.

It runs on top of [Rack](https://github.com/rack/rack) and works with any Rack-compatible server (Puma, WEBrick, Falcon, etc.).

## Requirements

- **Ruby 3.3+**
- A Rack handler, such as [Puma](https://github.com/puma/puma) or [WEBrick](https://github.com/ruby/webrick) (WEBrick already ships as a gem dependency; add Puma to your app's `Gemfile` for production use)

## Installation

```bash
gem install fastrb
```

Or in your `Gemfile`:

```ruby
gem "fastrb", "~> 0.2"
```

## Quick start

The fastest way to get started is with the CLI's project generator:

```bash
fastrb new myapp
cd myapp
bundle install
fastrb server
```

This scaffolds a minimal structure with `config.ru`, `app/main.rb`, `app/routes.rb`, and a sample RSpec test (see [Generated project structure](#generated-project-structure)).

## Core concepts

### The `App` DSL

`RubyAPI::App.new` takes a block that's run via `instance_eval`, so every route method (`get`, `post`, `group`, `plugin`, `use`, `before`, `register`, `rescue_from`, ...) is available directly inside it:

```ruby
app = RubyAPI::App.new do
  get "/ping" do
    { pong: true }
  end
end
```

Supported HTTP methods: `get`, `post`, `put`, `patch`, `delete`, `options`, `head`, plus the generic `route(method, path, **opts, &block)`.

Each route block optionally receives the request's `Context` (`ctx`) — if the block doesn't declare any arguments, it simply won't get the context.

### Routes and path parameters

Routing is implemented with a **trie** (prefix tree), which keeps lookups efficient regardless of how many routes are registered. Path parameters use `:name`:

```ruby
get "/users/:id" do |ctx|
  { id: ctx.params[:id] } # a string, no type conversion applied
end
```

Query string parameters also land in `ctx.params`, merged with path parameters.

### Typing and automatic conversion

Declare the expected type for a parameter with the `params:` option. FastRb converts the value (a string coming from the URL) into the corresponding Ruby type before calling the block, and automatically responds with `422` if the conversion fails:

```ruby
get "/users/:id", params: { id: Integer } do |ctx|
  { id: ctx.params[:id] } # already an Integer
end
```

### Body validation with `Schema`

For request bodies (JSON), define a declarative `Schema`:

```ruby
class UserSchema < RubyAPI::Schema
  field :name, type: String
  field :age, type: Integer
end

post "/users", body: UserSchema do |ctx|
  { created: true, name: ctx.body.name, age: ctx.body.age }
end
```

- Missing fields produce the `"is required"` error.
- All validation errors are collected at once (it doesn't stop at the first one) and returned with `422` in the shape `{ "errors": { "field": "message" } }`.
- `ctx.body` exposes validated fields both via `[]` (`ctx.body[:name]`) and via method access (`ctx.body.name`).

### Route groups

`group` lets you compose path prefixes (including nested ones):

```ruby
group "/api" do
  group "/v1" do
    get "/users" do
      { users: [] }
    end
  end
end
# => GET /api/v1/users
```

### `before` / `after` hooks

Global hooks run before/after every route. If a `before` hook sets `ctx.response_status`, the chain is short-circuited and that response is returned immediately (this is how the CORS and Auth plugins implement blocking and preflight responses):

```ruby
before do |ctx|
  ctx.set(:request_id, SecureRandom.uuid)
end

after do |ctx|
  puts "responded: #{ctx.request.path_info}"
end
```

### Rack middleware

Regular Rack middleware (anything responding to `call(env)`) is registered with `use`:

```ruby
use RubyAPI::Middleware::StructuredLogger, output: $stdout
use SomeOtherRackMiddleware, option: :value
```

### Dependency injection

Register an object/factory in the container and inject it into specific routes' context with `inject:`:

```ruby
app = RubyAPI::App.new do
  register(:current_user) { CurrentUser.new }

  get "/profile", inject: [:current_user] do |ctx|
    user = ctx.get(:current_user)
    { name: user.name }
  end
end
```

Instances are resolved lazily and cached — the factory only runs once per container (singleton-like behavior).

### Access control with `depends`

`depends:` accepts a list of checks that run before the handler. Each check has a `check` (a `Proc`, a `Symbol` registered in the container, or a `Class` implementing `#call(ctx)`) and a `status` HTTP code to return on failure (defaults to `401`):

```ruby
get "/protected", depends: [{ check: ->(ctx) { ctx.get(:jwt_payload) }, status: 401 }] do
  { secret: "data" }
end
```

### Sessions

Sessions are stored in a signed cookie (`HMAC-SHA256`), Base64-encoded — no server-side state:

```ruby
post "/login" do |ctx|
  ctx.session[:user_id] = 42
  { logged_in: true }
end

get "/profile" do |ctx|
  { user_id: ctx.session[:user_id] }
end
```

> ⚠️ Set `secret_key` (see [Per-environment configuration](#per-environment-configuration)) in production — the default value (`"change_me_in_production"`) is insecure and predictable.

### File uploads

`multipart/form-data` requests are automatically parsed and exposed via `ctx.files`:

```ruby
post "/upload" do |ctx|
  file = ctx.files["file"]
  { filename: file.filename, type: file.type, content: file.read }
end
```

### Error handling

`rescue_from` maps exception classes to HTTP status codes. The exception is serialized as `{ "error": "ExceptionClassName", "message": "..." }`:

```ruby
app = RubyAPI::App.new do
  rescue_from CustomError, status: 404
  rescue_from ArgumentError, status: 422

  get "/error" do
    raise CustomError, "something went wrong"
  end
end
```

Unmapped exceptions continue to propagate normally (they are not swallowed).

### Official plugins

Plugins are classes that inherit from `RubyAPI::Plugin` and implement `self.on_load(app)`. They're activated with `plugin`:

```ruby
app = RubyAPI::App.new do
  plugin RubyAPI::Plugins::CORS, origins: ["https://example.com"]
  plugin RubyAPI::Plugins::JWT, secret: ENV["JWT_SECRET"]
  plugin RubyAPI::Plugins::Auth
  plugin RubyAPI::Plugins::Cache, default_ttl: 300
end
```

| Plugin | What it does | Main options |
|---|---|---|
| `CORS` | Adds CORS headers and answers `OPTIONS` preflight requests with `204` | `origins`, `methods`, `headers`, `allow_credentials`, `max_age` |
| `JWT` | Decodes the `Authorization` header and exposes the payload via `ctx.get(:jwt_payload)` | `secret`, `algorithm`, `header`, `prefix` |
| `Auth` | Blocks any route with `401` if there's no `jwt_payload` in the context (use it after `JWT`) | `unauthorized_status`, `unauthorized_body` |
| `Cache` | In-memory (single-process) cache accessible via `ctx.get(:cache)` | `default_ttl` |

You can also write your own plugins by inheriting from `RubyAPI::Plugin`:

```ruby
class MyPlugin < RubyAPI::Plugin
  option :greeting, "Hello"

  def self.on_load(app)
    app.get "/plugin-route" do
      { greeting: options[:greeting] }
    end
  end
end
```

### Structured logging and metrics

```ruby
use RubyAPI::Middleware::StructuredLogger, output: $stdout
use RubyAPI::Middleware::Metrics
```

- `StructuredLogger` emits one JSON line per request (`method`, `path`, `status`, `duration_ms`, `timestamp`).
- `Metrics` accumulates request count and average latency per route (`GET /path`), accessible via `#summary` on the middleware instance.

### WebSockets

```ruby
websocket "/ws" do |ws|
  ws.on_open { |conn| puts "connected" }
  ws.on_message do |msg|
    ws.send("echo: #{msg}")
  end
  ws.on_close { |err| puts "disconnected" }
end
```

The connection upgrade uses `rack.hijack`, so it requires a Rack server that supports hijacking (Puma and WEBrick do; check compatibility if you switch servers).

### Server-Sent Events

```ruby
get "/events" do |ctx|
  ctx.sse do |out|
    loop do
      out.send(event: "tick", data: Time.now.to_s)
      sleep 1
    end
  end
end
```

### HTTP streaming

For chunked HTTP responses (not SSE):

```ruby
get "/download" do |ctx|
  ctx.stream do |out|
    10.times { |i| out.write("chunk #{i}\n") }
  end
end
```

The block runs on a separate thread; use `out.write` to send data, and the stream closes automatically once the block finishes.

### Background jobs

An **in-process** async job queue (one `Thread` + `Queue` per job class — not distributed or persistent):

```ruby
class MyJob < RubyAPI::Job
  def self.perform(user_id)
    UserMailer.send_welcome(user_id).deliver
  end
end

MyJob.enqueue(user_id) # runs asynchronously
MyJob.results          # successfully completed jobs
MyJob.errors           # jobs that raised an exception
```

For persistent/distributed queues in production, prefer a dedicated solution (Sidekiq, GoodJob, etc.) — this mechanism is meant for lightweight, non-critical tasks.

### OpenAPI and Swagger UI

Every FastRb app automatically exposes:

- `GET /openapi.json` — an OpenAPI 3.0 spec generated from the registered routes
- `GET /docs` — Swagger UI served from a CDN, pointing at `/openapi.json`

> **Note:** the current spec generation only includes path, method, and path parameters (typed as `string`); query parameters, `Schema` request bodies, and custom responses are not yet reflected in the generated document.

## Supported types

Used both in a route's `params:` and in `Schema` fields:

| Type | Example |
|---|---|
| `String` | `"hello"` |
| `Integer` | `42` |
| `Float` | `3.14` |
| `RubyAPI::Boolean` | `true` / `false` (accepts `"true"/"1"/"yes"` and `"false"/"0"/"no"`) |
| `Date` | `2026-01-15` |
| `Time` | `2026-01-15T10:30:00Z` |
| `DateTime` | `2026-01-15T10:30:00` |
| `Array` | `[1, 2, 3]` (or a JSON-serialized string) |
| `Hash` | `{"key": "value"}` (or a JSON-serialized string) |
| `RubyAPI::UUID` | `550e8400-e29b-41d4-a716-446655440000` |
| `RubyAPI::Decimal` | `3.14` (alias for `BigDecimal`) |
| `Symbol` | `:hello` |

## Per-environment configuration

```bash
FASTRB_ENV=production fastrb server
```

```ruby
# config/environments/production.rb
setting :port, 80
setting :secret_key, ENV["SECRET_KEY"]
```

Default settings: `port` (`3000`), `host` (`"0.0.0.0"`), `log_level` (`"info"`), `secret_key` (`"change_me_in_production"`).

> ⚠️ Loading the environment file (`config.load_environment_config`) is **not automatic** — you need to call it explicitly in your `config.ru` or entry point, e.g.:
> ```ruby
> app = App.new
> app.config.load_environment_config
> run app
> ```

## CLI

```bash
fastrb new <name>    # scaffolds a new FastRb project
fastrb server        # starts the server from config.ru in the current directory
fastrb version        # prints the installed version
```

`fastrb server` boots the app via `Rackup::Server`, on port `3000`, listening on all interfaces (`0.0.0.0`).

## Generated project structure

```
myapp/
├── Gemfile
├── config.ru
├── app/
│   ├── main.rb        # App class < RubyAPI::App
│   └── routes.rb       # Routes.apply(app) module
├── config/
│   └── environments/
├── public/
├── spec/
│   ├── unit/
│   ├── requests/
│   └── spec_helper.rb
└── README.md
```

## Testing

FastRb itself is tested with RSpec + `rack-test`:

```bash
bundle exec rspec
```

To test your own FastRb application the same way, include `Rack::Test::Methods` in your spec and define an `app` method that returns your application instance.

## Known limitations

Points identified while analyzing the source code, useful for anyone adopting or contributing to the project:

- **Inconsistent internal namespace:** the gem is called `fastrb`, but all the code lives under the `RubyAPI` module (`RubyAPI::App`, `RubyAPI::Schema`, etc.) — likely a leftover from an earlier project name.
- **`config.load_environment_config` is never called automatically** anywhere in the framework (not in `App#initialize`, nor in the CLI) — it must be triggered manually.
- **Incomplete OpenAPI output:** the spec generated at `/openapi.json` doesn't document query parameters, `Schema` request bodies, or multiple response statuses.
- **Cache and job queue are in-memory, single-process only** — they don't survive a restart and don't work across multiple instances/workers.
- **`Session` falls back to an insecure default secret** (`"fastrb_default_secret"` / `"change_me_in_production"`) if `secret_key` isn't configured — this must be set manually in production.
- **The WebSocket handler spawns one `Thread` per connection**, with no pooling or limit — this can become a bottleneck under high concurrency.
- The `Gemfile` generated by the CLI (`fastrb new`) adds `puma`, while the original README mentioned support for **Falcon** without that dependency being declared anywhere in the project — worth confirming which server is actually recommended before advertising it as a requirement.

## Contributing

1. Fork the repo and branch off `main`.
2. Run `bundle install` and `bundle exec rspec` before opening a PR — CI (`.github/workflows/ci.yml`) runs the full test suite on Ruby 3.3 on every push/PR.
3. Releases are published automatically (GitHub Packages + RubyGems) when a `v*` tag is created on `main`.

## License

[MIT](LICENSE)
