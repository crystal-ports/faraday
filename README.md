# Faraday — Crystal Port

[![Crystal](https://img.shields.io/badge/crystal-%3E%3D1.14.0-black)](https://crystal-lang.org)

Crystal port of [lostisland/faraday](https://github.com/lostisland/faraday) — an HTTP client library
abstraction layer with Rack-inspired middleware. Transpiled with
[alexanderadam/ruby_to_crystal](https://github.com/alexanderadam/ruby_to_crystal).

## Installation

Add to your `shard.yml`:

```yaml
dependencies:
  faraday:
    github: crystal-ports/faraday
```

Then run `shards install`.

## Quick Start

```crystal
require "faraday"

conn = Faraday.new(url: "https://api.example.com") do |f|
  f.request  :json
  f.response :json
  f.response :raise_error
  f.adapter  :net_http
end

response = conn.get("/users")
response.body  # => parsed Hash
```

## Middleware

```crystal
conn = Faraday.new(url: "https://api.example.com") do |f|
  f.request  :authorization, "Bearer", "my-token"
  f.request  :url_encoded
  f.response :logger
  f.response :raise_error
  f.adapter  :net_http
end
```

Available middleware:
- **Request:** `:authorization`, `:json`, `:url_encoded`, `:instrumentation`
- **Response:** `:json`, `:logger`, `:raise_error`

## Testing

```crystal
conn = Faraday.new do |f|
  f.adapter :test do |stub|
    stub.get("/hello") { [200, {"Content-Type" => "text/plain"}, "world"] }
    stub.post("/data") { |env| [201, {}, env.request_body] }
  end
end

conn.get("/hello").body  # => "world"
```

## Adapter

The only bundled adapter is `:net_http` (Crystal stdlib `HTTP::Client`). It is the default.

## Supported Crystal Versions

Crystal ≥ 1.14.0.

## Running Specs

```
shards install
crystal spec
# 110 examples, 0 failures
```

## What Is Not Ported

- Parallel request support — `env.parallel?` always returns `false`
- Non-stdlib adapters (Typhoeus, Excon, etc.)
- Multipart / file upload (`Faraday::UploadIO`)

## Architecture

See [`.claude/CLAUDE.md`](.claude/CLAUDE.md) for the architecture overview, directory map,
middleware/adapter implementation patterns, and Crystal-specific decisions.

## Origin

The source files were `git mv`'d from their Ruby paths to Crystal paths, so the full Ruby commit
history is reachable via `git log --follow src/faraday/foo.cr`.

## Copyright

&copy; 2009 - 2023, the Faraday Team.
Crystal port by [crystal-ports](https://github.com/crystal-ports).
