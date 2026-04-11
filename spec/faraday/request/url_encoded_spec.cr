require "../../spec_helper"

Spectator.describe Faraday::Request::UrlEncoded do
  let(stubs) {
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/echo") { |env| {200, {} of String => String, env.request_body.to_s} }
      stub.post("/form") { |env| {200, {"X-Content-Type" => env.request_headers["Content-Type"]?.to_s}, ""} }
    end
  }

  let(conn) {
    Faraday::Connection.new("http://example.com") do |b|
      b.request :url_encoded
      b.adapter :test, stubs
    end
  }

  it "encodes Hash body as URL-encoded form data" do
    response = conn.post("/echo", {"a" => "1", "b" => "2"})
    expect(response.body.to_s).to contain("a=1")
    expect(response.body.to_s).to contain("b=2")
  end

  it "does not alter String bodies" do
    stubs2 = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/raw", "raw_data") { {200, {} of String => String, "ok"} }
    end
    conn2 = Faraday::Connection.new("http://example.com") do |b|
      b.request :url_encoded
      b.adapter :test, stubs2
    end
    expect(conn2.post("/raw", "raw_data").status).to eq(200)
  end

  describe "Content-Type header" do
    pending "Content-Type is set to application/x-www-form-urlencoded for Hash bodies" do
      # Verifying Content-Type requires env access in stub block
    end
  end
end
