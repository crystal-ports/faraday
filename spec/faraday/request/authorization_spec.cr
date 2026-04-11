require "../../spec_helper"

# Faraday::Request::Authorization middleware adds an Authorization header.
# Ruby supports :basic_auth and token-based auth helpers.
# Crystal implementation may differ; these tests reflect what is likely available.

Spectator.describe Faraday::Request::Authorization do
  describe "basic authentication" do
    let(stubs) {
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get("/protected") { |env|
          {200, {} of String => String, env.request_headers["Authorization"]?.to_s}
        }
      end
    }

    let(conn) {
      Faraday::Connection.new("http://example.com") do |b|
        b.request :authorization, :basic, "user", "pass"
        b.adapter :test, stubs
      end
    }

    it "adds a Basic Authorization header" do
      response = conn.get("/protected")
      expect(response.body.to_s).to start_with("Basic ")
    end
  end

  describe "token authentication" do
    let(stubs) {
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get("/secure") { |env|
          {200, {} of String => String, env.request_headers["Authorization"]?.to_s}
        }
      end
    }

    let(conn) {
      Faraday::Connection.new("http://example.com") do |b|
        b.request :authorization, :token, "mytoken123"
        b.adapter :test, stubs
      end
    }

    it "adds a Token Authorization header" do
      response = conn.get("/secure")
      expect(response.body.to_s).to contain("mytoken123")
    end
  end

  describe "Bearer token" do
    let(stubs) {
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get("/api") { |env|
          {200, {} of String => String, env.request_headers["Authorization"]?.to_s}
        }
      end
    }

    let(conn) {
      Faraday::Connection.new("http://example.com") do |b|
        b.request :authorization, "Bearer", "mytoken"
        b.adapter :test, stubs
      end
    }

    it "adds a Bearer Authorization header" do
      response = conn.get("/api")
      expect(response.body.to_s).to contain("Bearer")
      expect(response.body.to_s).to contain("mytoken")
    end
  end

  describe "when Authorization header is already set" do
    pending "Authorization middleware should not overwrite an existing Authorization header" do
      # Ruby: if Authorization is already set in the request, the middleware skips
    end
  end

  describe "Ruby-specific helpers" do
    pending "Faraday::Request::Authorization.header(:basic, user, pass) is a Ruby-specific class method" do
    end
  end
end
