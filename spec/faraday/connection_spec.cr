require "../spec_helper"

Spectator.describe Faraday::Connection do
  let(url) { "http://httpbin.org/get" }
  subject { Faraday::Connection.new(url) }

  describe "initialization with URL string" do
    it "sets the url_prefix host" do
      expect(subject.url_prefix.host).to eq("httpbin.org")
    end

    it "sets the url_prefix path" do
      expect(subject.url_prefix.path).to eq("/get")
    end

    it "initializes with empty params" do
      expect(subject.params).to be_empty
    end

    it "initializes with an HTTP::Headers instance" do
      expect(subject.headers).to be_a(HTTP::Headers)
    end
  end

  describe "initialization without URL" do
    subject { Faraday::Connection.new }

    it "has a url_prefix" do
      expect(subject.url_prefix).not_to be_nil
    end
  end

  describe "initialization with block" do
    it "yields self for configuration" do
      configured = false
      Faraday::Connection.new(url) { |_c| configured = true }
      expect(configured).to be_true
    end

    it "allows configuring the builder in the block" do
      conn = Faraday::Connection.new(url) { |c| c.response :raise_error }
      expect(conn.builder.handlers.size).to eq(1)
    end
  end

  describe "#headers" do
    it "allows setting a header" do
      subject.headers["X-Custom"] = "value"
      expect(subject.headers["X-Custom"]).to eq("value")
    end

    it "is case-insensitive" do
      subject.headers["Content-Type"] = "text/plain"
      expect(subject.headers["content-type"]).to eq("text/plain")
    end
  end

  describe "#params" do
    it "allows setting params" do
      subject.params["foo"] = "bar"
      expect(subject.params["foo"]).to eq("bar")
    end
  end

  describe "#builder" do
    it "returns a RackBuilder" do
      expect(subject.builder).to be_a(Faraday::RackBuilder)
    end
  end

  describe "#ssl" do
    it "returns an SSLOptions" do
      expect(subject.ssl).to be_a(Faraday::SSLOptions)
    end
  end

  describe "#build_exclusive_url" do
    context "with base url" do
      let(url) { "http://httpbin.org/prefix" }

      it "builds a URL from a path string" do
        uri = subject.build_exclusive_url("/get")
        expect(uri.host).to eq("httpbin.org")
        expect(uri.path).to eq("/get")
      end

      it "merges query params into the URL" do
        uri = subject.build_exclusive_url("/get", {"a" => "1"})
        expect(uri.query).to contain("a=1")
      end

      it "handles multiple params" do
        uri = subject.build_exclusive_url("/search", {"q" => "crystal", "lang" => "cr"})
        expect(uri.query).to contain("q=crystal")
        expect(uri.query).to contain("lang=cr")
      end
    end

    context "with empty path" do
      it "returns the base url" do
        uri = subject.build_exclusive_url("")
        expect(uri.host).to eq("httpbin.org")
      end
    end
  end

  describe "METHODS constant" do
    it "includes :get" do
      expect(Faraday::Connection::METHODS).to contain(:get)
    end

    it "includes :post" do
      expect(Faraday::Connection::METHODS).to contain(:post)
    end

    it "includes :put" do
      expect(Faraday::Connection::METHODS).to contain(:put)
    end

    it "includes :delete" do
      expect(Faraday::Connection::METHODS).to contain(:delete)
    end

    it "includes :head" do
      expect(Faraday::Connection::METHODS).to contain(:head)
    end

    it "includes :patch" do
      expect(Faraday::Connection::METHODS).to contain(:patch)
    end

    it "includes :options" do
      expect(Faraday::Connection::METHODS).to contain(:options)
    end
  end

  describe "making requests with test adapter" do
    let(stubs) {
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get("/hello") { {200, {"Content-Type" => "text/plain"}, "world"} }
        stub.post("/data", "payload") { {201, {} of String => String, "created"} }
        stub.put("/item", "update") { {200, {} of String => String, "updated"} }
        stub.delete("/item") { {204, {} of String => String, ""} }
      end
    }

    let(test_conn) {
      Faraday::Connection.new("http://example.com") do |b|
        b.adapter :test, stubs
      end
    }

    it "performs a GET request" do
      response = test_conn.get("/hello")
      expect(response.status).to eq(200)
      expect(response.body).to eq("world")
    end

    it "performs a POST request" do
      response = test_conn.post("/data", "payload")
      expect(response.status).to eq(201)
    end

    it "performs a PUT request" do
      response = test_conn.put("/item", "update")
      expect(response.status).to eq(200)
    end

    it "performs a DELETE request" do
      response = test_conn.delete("/item")
      expect(response.status).to eq(204)
    end
  end

  describe "proxy" do
    pending "proxy configuration support" do
      # Crystal's proxy support may differ from Ruby
    end
  end

  describe "#dup" do
    pending "dup is not confirmed available in Crystal Connection" do
    end
  end

  describe "parallel requests" do
    pending "parallel request support is not ported to Crystal" do
    end
  end
end
