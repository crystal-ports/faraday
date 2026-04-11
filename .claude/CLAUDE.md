# Claude AI Agent Instructions for Faraday (Crystal Port)

## What This Repo Is
A **Crystal port** of [lostisland/faraday](https://github.com/lostisland/faraday), transpiled via
[alexanderadam/ruby_to_crystal](https://github.com/alexanderadam/ruby_to_crystal) then hand-cleaned.
Language: Crystal ≥ 1.14.0. Specs: Spectator (110 examples, 0 failures).

## Quick Reference

| What you want | Where to look |
|---|---|
| Coding conventions | `.ai/guidelines.md` |
| Entry point / load order | `src/faraday.cr` |
| Middleware stack builder | `src/faraday/rack_builder.cr` |
| Request/response bag | `src/faraday/options/env.cr` |
| HTTP adapter (stdlib) | `src/faraday/adapter/net_http.cr` |
| Test adapter / stubs | `src/faraday/adapter/test.cr` |
| Handler base types | `src/faraday/handler.cr` |
| Spec examples (all features) | `spec/faraday_spec.cr` |
| Error hierarchy | `src/faraday/error.cr` |

## Architecture

```
abstract class Handler
  abstract def call(env : Env) : Response

class Middleware < Handler    # wraps the next handler; call @app.call(env) to continue
class Adapter   < Handler    # terminal — makes the actual HTTP request
```

`RackBuilder` folds `Array(HandlerSpec)` + `AdapterSpec` into a nested handler chain.
`Faraday::Env` is the request/response bag flowing through every `call`. `Response#finish`
is synchronous; `on_complete` callbacks fire immediately when the adapter returns.

## Directory Map

```
src/faraday.cr                   entry point (all requires in load order)
src/faraday/handler.cr           Handler / HandlerSpec / AdapterSpec base types
src/faraday/rack_builder.cr      builds the middleware stack
src/faraday/connection.cr        main user-facing object
src/faraday/options/env.cr       request/response bag
src/faraday/adapter/net_http.cr  default adapter (Crystal HTTP::Client)
src/faraday/adapter/test.cr      in-memory stub adapter
spec/faraday_spec.cr             110 Spectator examples
```

## Key Crystal vs Ruby Differences in This Port
- `Symbol#upcase` doesn't exist → use `sym.to_s.upcase`
- `HTTP::Client` timeouts require `Time::Span` → use `n.seconds` not bare `n`
- No `method_missing` → middleware registration uses explicit `HandlerSpec`/`AdapterSpec` wrappers
- `parallel?` always returns `false` — no parallel request support
- `Response#finish` is synchronous; `on_complete` callbacks fire immediately

## What Is Not Ported
- Parallel request support
- Non-stdlib adapters (Typhoeus, Excon, etc.)
- Multipart / file upload (`Faraday::UploadIO`)
