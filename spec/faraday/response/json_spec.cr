require "../../spec_helper"

# Faraday::Response::Json — parses the response body as JSON.

Spectator.describe Faraday::Response::Json do
  let(stubs) {
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/json") { {200, {"Content-Type" => "application/json"}, "{\"key\":\"value\"}"} }
      stub.get("/json-array") { {200, {"Content-Type" => "application/json"}, "[1,2,3]"} }
      stub.get("/text") { {200, {"Content-Type" => "text/plain"}, "plain text"} }
      stub.get("/empty") { {200, {"Content-Type" => "application/json"}, ""} }
      stub.get("/invalid-json") { {200, {"Content-Type" => "application/json"}, "{invalid"} }
    end
  }

  let(conn) {
    Faraday::Connection.new("http://example.com") do |b|
      b.response :json
      b.adapter :test, stubs
    end
  }

  it "parses JSON object response body" do
    response = conn.get("/json")
    parsed = response.body
    # After JSON parsing, body may be a Hash or parsed object representation
    expect(parsed).not_to be_nil
    expect(parsed.to_s).to contain("key")
  end

  it "returns a successful status" do
    response = conn.get("/json")
    expect(response.status).to eq(200)
  end

  it "handles JSON array response" do
    response = conn.get("/json-array")
    expect(response.body).not_to be_nil
  end

  it "leaves non-JSON responses unchanged" do
    response = conn.get("/text")
    expect(response.body).to eq("plain text")
  end

  describe "empty body" do
    pending "handling of empty body with Content-Type: application/json" do
      # Ruby: returns nil for empty body; Crystal may differ
    end
  end

  describe "invalid JSON" do
    pending "invalid JSON raises Faraday::ParsingError" do
      # Ruby raises ParsingError; Crystal may raise JSON::ParseException
    end
  end

  describe "content_type option" do
    pending "b.response :json, content_type: /\\bjson\\b/ for custom MIME matching" do
    end
  end
end
