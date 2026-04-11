require "../../spec_helper"

# Faraday::Request::Json — encodes the request body as JSON and sets Content-Type.

Spectator.describe Faraday::Request::Json do
  let(stubs) {
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/json") { |env|
        {200, {"X-Request-CT" => env.request_headers["Content-Type"]?.to_s}, env.request_body.to_s}
      }
      stub.post("/passthrough", "already a string") { {200, {} of String => String, "ok"} }
    end
  }

  let(conn) {
    Faraday::Connection.new("http://example.com") do |b|
      b.request :json
      b.adapter :test, stubs
    end
  }

  it "encodes a Hash body as JSON" do
    response = conn.post("/json", {"key" => "value"})
    expect(response.body.to_s).to contain("\"key\"")
    expect(response.body.to_s).to contain("\"value\"")
  end

  it "sets Content-Type to application/json" do
    response = conn.post("/json", {"a" => "1"})
    expect(response.headers["X-Request-CT"]).to contain("application/json")
  end

  it "does not double-encode an already-String body" do
    response = conn.post("/passthrough", "already a string")
    expect(response.status).to eq(200)
  end

  describe "JSON encoding of various types" do
    let(echo_stubs) {
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post("/echo") { |env| {200, {} of String => String, env.request_body.to_s} }
      end
    }

    let(json_conn) {
      Faraday::Connection.new("http://example.com") do |b|
        b.request :json
        b.adapter :test, echo_stubs
      end
    }

    it "encodes arrays" do
      response = json_conn.post("/echo", [1, 2, 3])
      expect(response.body.to_s).to contain("[")
    end

    it "encodes nested structures" do
      response = json_conn.post("/echo", {"a" => {"b" => "c"}})
      expect(response.body.to_s).to contain("\"a\"")
    end
  end

  describe "Accept header" do
    pending "Request::Json may also set Accept: application/json" do
    end
  end
end
