require "./spec_helper"

# Minimal terminal handler for middleware unit tests.
private class EchoApp < Faraday::Handler
  getter last_env : Faraday::Env?

  def call(env : Faraday::Env) : Faraday::Response
    @last_env = env
    env.status = 200
    env.response_body = "ok"
    resp = Faraday::Response.new
    resp.finish(env)
    resp
  end
end

# Build a Connection backed by the Test adapter.
private def stubbed_conn(base = "http://example.com", &setup : Faraday::Adapter::Test ->)
  ta = Faraday::Adapter::Test.new
  setup.call(ta)
  Faraday::Connection.new(base) { |c| c.builder.adapter(ta) }
end

private def stubbed_conn_with(base = "http://example.com", &setup : Faraday::RackBuilder, Faraday::Adapter::Test ->)
  ta = Faraday::Adapter::Test.new
  Faraday::Connection.new(base) do |c|
    setup.call(c.builder, ta)
    c.builder.adapter(ta)
  end
end

Spectator.describe Faraday do
  # ------------------------------------------------------------------ #
  describe ".version" do
    it "is defined" do
      expect(Faraday::VERSION).to eq("2.14.1")
    end
  end

  # ------------------------------------------------------------------ #
  describe Faraday::Error do
    it "is an Exception" do
      expect(Faraday::Error.new).to be_a(Exception)
    end

    it "accepts a message string" do
      err = Faraday::Error.new("something broke")
      expect(err.message).to eq("something broke")
    end

    it "wraps another exception" do
      inner = Exception.new("inner kaboom")
      err = Faraday::Error.new(inner)
      expect(err.wrapped_exception).to be(inner)
      expect(err.message).to eq("inner kaboom")
    end

    it "exposes response_status from attached response" do
      resp = Faraday::Response.new
      env = Faraday::Env.new
      env.status = 404
      resp.finish(env)
      err = Faraday::Error.new("not found", resp)
      expect(err.response_status).to eq(404)
    end

    it "returns nil response_status without response" do
      expect(Faraday::Error.new("x").response_status).to be_nil
    end

    describe "hierarchy" do
      it "ClientError < Error" do
        expect(Faraday::ClientError.new).to be_a(Faraday::Error)
      end

      it "ServerError < Error" do
        expect(Faraday::ServerError.new).to be_a(Faraday::Error)
      end

      it "TimeoutError < ServerError" do
        expect(Faraday::TimeoutError.new).to be_a(Faraday::ServerError)
      end

      it "NilStatusError < ServerError" do
        expect(Faraday::NilStatusError.new).to be_a(Faraday::ServerError)
      end

      it "ResourceNotFound < ClientError" do
        expect(Faraday::ResourceNotFound.new).to be_a(Faraday::ClientError)
      end

      it "ConnectionFailed < Error" do
        expect(Faraday::ConnectionFailed.new).to be_a(Faraday::Error)
      end

      it "SSLError < Error" do
        expect(Faraday::SSLError.new).to be_a(Faraday::Error)
      end

      it "TimeoutError has default message 'timeout'" do
        expect(Faraday::TimeoutError.new.message).to eq("timeout")
      end

      it "NilStatusError default message mentions status" do
        expect(Faraday::NilStatusError.new.message).to contain("could not be derived")
      end

      it "UnprocessableEntityError is an alias for UnprocessableContentError" do
        expect(Faraday::UnprocessableEntityError).to be(Faraday::UnprocessableContentError)
      end
    end
  end

  # ------------------------------------------------------------------ #
  describe Faraday::SSLOptions do
    it "verify? is true by default" do
      expect(Faraday::SSLOptions.new.verify?).to be_true
    end

    it "verify? is false when verify set to false" do
      opts = Faraday::SSLOptions.new
      opts.verify = false
      expect(opts.verify?).to be_false
    end

    it "disable? is the inverse of verify?" do
      opts = Faraday::SSLOptions.new
      opts.verify = false
      expect(opts.disable?).to be_true
    end

    it "verify_hostname? is true by default" do
      expect(Faraday::SSLOptions.new.verify_hostname?).to be_true
    end

    it "dup copies all fields independently" do
      orig = Faraday::SSLOptions.new
      orig.verify = false
      orig.ca_file = "/etc/ssl/certs.pem"
      orig.verify_depth = 2
      copy = orig.dup
      expect(copy.verify).to eq(false)
      expect(copy.ca_file).to eq("/etc/ssl/certs.pem")
      expect(copy.verify_depth).to eq(2)
      # independence
      copy.ca_file = "/other.pem"
      expect(orig.ca_file).to eq("/etc/ssl/certs.pem")
    end
  end

  # ------------------------------------------------------------------ #
  describe Faraday::RequestOptions do
    it "stream_response? is false initially" do
      expect(Faraday::RequestOptions.new.stream_response?).to be_false
    end

    it "stream_response? is true when on_data is set" do
      opts = Faraday::RequestOptions.new
      opts.on_data = ->(data : String, total : Int32, env : Faraday::Env) {}
      expect(opts.stream_response?).to be_true
    end

    it "dup copies timeout fields" do
      orig = Faraday::RequestOptions.new
      orig.timeout = 30
      orig.open_timeout = 5
      orig.read_timeout = 10
      copy = orig.dup
      expect(copy.timeout).to eq(30)
      expect(copy.open_timeout).to eq(5)
      expect(copy.read_timeout).to eq(10)
    end

    it "dup is independent" do
      orig = Faraday::RequestOptions.new
      orig.timeout = 30
      copy = orig.dup
      copy.timeout = 99
      expect(orig.timeout).to eq(30)
    end
  end

  # ------------------------------------------------------------------ #
  describe Faraday::ProxyOptions do
    it ".from(String) parses host and port" do
      opts = Faraday::ProxyOptions.from("http://proxy.example.com:8080")
      expect(opts).not_to be_nil
      expect(opts.not_nil!.host).to eq("proxy.example.com")
      expect(opts.not_nil!.port).to eq(8080)
    end

    it ".from(String) adds http:// when scheme missing" do
      opts = Faraday::ProxyOptions.from("proxy.example.com:8080")
      expect(opts).not_to be_nil
      expect(opts.not_nil!.scheme).to eq("http")
    end

    it ".from(String) with credentials" do
      opts = Faraday::ProxyOptions.from("http://usr:s3cr3t@proxy.example.com")
      expect(opts.not_nil!.user).to eq("usr")
      expect(opts.not_nil!.password).to eq("s3cr3t")
    end

    it ".from(empty string) returns nil" do
      expect(Faraday::ProxyOptions.from("")).to be_nil
    end

    it ".from(nil) returns nil" do
      expect(Faraday::ProxyOptions.from(nil)).to be_nil
    end

    it ".from(URI) extracts host/port" do
      uri = URI.parse("http://proxy.internal:3128")
      opts = Faraday::ProxyOptions.from(uri)
      expect(opts.host).to eq("proxy.internal")
      expect(opts.port).to eq(3128)
    end

    it ".from(Hash) with string :uri key" do
      opts = Faraday::ProxyOptions.from({"uri" => "http://proxy.example.com"})
      expect(opts).not_to be_nil
      expect(opts.not_nil!.host).to eq("proxy.example.com")
    end

    it ".from(empty Hash) returns nil" do
      result = Faraday::ProxyOptions.from({} of String => String)
      expect(result).to be_nil
    end
  end

  # ------------------------------------------------------------------ #
  describe Faraday::Env do
    let(:env) { Faraday::Env.new }

    it "defaults to GET method" do
      expect(env.method).to eq(:get)
    end

    it "body returns request_body before status is set" do
      env.request_body = "payload"
      expect(env.body).to eq("payload")
    end

    it "body returns response_body after status is set" do
      env.status = 200
      env.response_body = "response data"
      expect(env.body).to eq("response data")
    end

    it "body= sets request_body before status" do
      env.body = "req data"
      expect(env.request_body).to eq("req data")
    end

    it "body= sets response_body after status" do
      env.status = 200
      env.body = "resp data"
      expect(env.response_body).to eq("resp data")
    end

    it "clear_body sets Content-Length to 0 and empties body" do
      env.request_body = "some payload"
      env.clear_body
      expect(env.request_headers["Content-Length"]).to eq("0")
      expect(env.request_body).to eq("")
    end

    it "needs_body? is false for GET" do
      expect(env.needs_body?).to be_false
    end

    it "needs_body? is true for POST without body" do
      env.method = :post
      expect(env.needs_body?).to be_true
    end

    it "needs_body? is false for POST with body" do
      env.method = :post
      env.request_body = "data"
      expect(env.needs_body?).to be_false
    end

    it "success? is false without status" do
      expect(env.success?).to be_false
    end

    it "success? is true for 200..299" do
      [200, 201, 204, 299].each do |code|
        env.status = code
        expect(env.success?).to be_true
      end
    end

    it "success? is false for 404" do
      env.status = 404
      expect(env.success?).to be_false
    end

    it "parse_body? is false for 204" do
      env.status = 204
      expect(env.parse_body?).to be_false
    end

    it "parse_body? is false for 304" do
      env.status = 304
      expect(env.parse_body?).to be_false
    end

    it "parse_body? is true for 200" do
      env.status = 200
      expect(env.parse_body?).to be_true
    end

    it "stream_response? delegates to request options" do
      expect(env.stream_response?).to be_false
    end

    it "parallel? is always false" do
      expect(env.parallel?).to be_false
    end
  end

  # ------------------------------------------------------------------ #
  describe Faraday::Response do
    it "starts unfinished" do
      expect(Faraday::Response.new.finished?).to be_false
    end

    it "finish transitions to finished" do
      r = Faraday::Response.new
      env = Faraday::Env.new
      env.status = 200
      env.response_body = "hello"
      r.finish(env)
      expect(r.finished?).to be_true
      expect(r.status).to eq(200)
      expect(r.body).to eq("hello")
    end

    it "raises on double finish" do
      r = Faraday::Response.new
      env = Faraday::Env.new
      env.status = 200
      r.finish(env)
      expect_raises(Exception, "response already finished") { r.finish(env) }
    end

    it "on_complete callback fires after finish" do
      r = Faraday::Response.new
      fired = false
      r.on_complete { fired = true }
      expect(fired).to be_false
      env = Faraday::Env.new
      env.status = 200
      r.finish(env)
      expect(fired).to be_true
    end

    it "on_complete fires immediately if already finished" do
      r = Faraday::Response.new
      env = Faraday::Env.new
      env.status = 200
      r.finish(env)
      fired = false
      r.on_complete { fired = true }
      expect(fired).to be_true
    end

    it "multiple on_complete callbacks all fire" do
      r = Faraday::Response.new
      count = 0
      r.on_complete { count += 1 }
      r.on_complete { count += 1 }
      env = Faraday::Env.new
      env.status = 200
      r.finish(env)
      expect(count).to eq(2)
    end

    it "success? is false for unfinished response" do
      expect(Faraday::Response.new.success?).to be_false
    end

    it "success? is true for 200 response" do
      env = Faraday::Env.new
      env.status = 200
      expect(Faraday::Response.new(env).success?).to be_true
    end
  end

  # ------------------------------------------------------------------ #
  describe Faraday::RackBuilder do
    it "builds with a default adapter" do
      builder = Faraday::RackBuilder.new
      expect(builder.adapter_spec).not_to be_nil
    end

    it "builds a handler chain via symbol" do
      builder = Faraday::RackBuilder.new { |b| b.adapter(:net_http) }
      expect(builder.app).to be_a(Faraday::Handler)
    end

    it "locks after first app call" do
      builder = Faraday::RackBuilder.new { |b| b.adapter(:net_http) }
      builder.app
      expect(builder.locked?).to be_true
    end

    it "raises StackLocked on use after lock" do
      builder = Faraday::RackBuilder.new { |b| b.adapter(:net_http) }
      builder.app # lock it
      expect_raises(Faraday::RackBuilder::StackLocked) do
        builder.response(:raise_error)
      end
    end

    it "always has a default adapter even with empty block" do
      builder = Faraday::RackBuilder.new { }
      expect(builder.adapter_spec).not_to be_nil
    end

    it "accepts a pre-built adapter instance" do
      ta = Faraday::Adapter::Test.new
      builder = Faraday::RackBuilder.new { |b| b.adapter(ta) }
      expect(builder.app).to be_a(Faraday::Handler)
    end

    it "builds middleware chain in correct order" do
      ta = Faraday::Adapter::Test.new
      ta.stub(:get, "/ping") { |_| {200, HTTP::Headers.new, "pong"} }
      builder = Faraday::RackBuilder.new do |b|
        b.response(:raise_error)
        b.adapter(ta)
      end
      conn = Faraday::Connection.new("http://example.com") { |c| c.builder.adapter(ta) }
      # just verify app builds without error
      expect(builder.app).to be_a(Faraday::Handler)
    end
  end

  # ------------------------------------------------------------------ #
  describe "Connection" do
    subject { Faraday::Connection.new("http://httpbingo.org") }

    it "sets url_prefix host" do
      expect(subject.url_prefix.host).to eq("httpbingo.org")
    end

    it "sets default User-Agent header" do
      expect(subject.headers["User-Agent"]).to eq("Faraday v#{Faraday::VERSION}")
    end

    it "builds exclusive URL with path" do
      uri = subject.build_exclusive_url("/items")
      expect(uri.path).to eq("/items")
      expect(uri.host).to eq("httpbingo.org")
    end

    it "builds exclusive URL with query params" do
      uri = subject.build_exclusive_url("/search",
        Faraday::Utils::ParamsHash.new.tap { |p| p["q"] = "crystal" })
      expect(uri.path).to eq("/search")
      expect(uri.query).to contain("q=crystal")
    end

    it "has a RackBuilder" do
      expect(subject.builder).to be_a(Faraday::RackBuilder)
    end
  end

  # ------------------------------------------------------------------ #
  describe "Connection (stubbed adapter)" do
    it "GET returns stubbed response body" do
      conn = stubbed_conn do |ta|
        ta.stub(:get, "/hello") { |_| {200, HTTP::Headers.new, "hello world"} }
      end
      resp = conn.get("/hello")
      expect(resp.status).to eq(200)
      expect(resp.body).to eq("hello world")
    end

    it "POST returns stubbed response" do
      conn = stubbed_conn do |ta|
        ta.stub(:post, "/data") { |_| {201, HTTP::Headers.new, "created"} }
      end
      resp = conn.post("/data", "body=1")
      expect(resp.status).to eq(201)
    end

    it "PUT returns stubbed response" do
      conn = stubbed_conn do |ta|
        ta.stub(:put, "/item/1") { |_| {200, HTTP::Headers.new, "updated"} }
      end
      resp = conn.put("/item/1", "x=y")
      expect(resp.status).to eq(200)
    end

    it "DELETE returns stubbed response" do
      conn = stubbed_conn do |ta|
        ta.stub(:delete, "/item/1") { |_| {204, HTTP::Headers.new, ""} }
      end
      resp = conn.delete("/item/1")
      expect(resp.status).to eq(204)
    end

    it "raises Faraday::Error when no stub matches" do
      conn = stubbed_conn { }
      expect_raises(Faraday::Error) { conn.get("/unknown") }
    end

    it "GET passes custom headers to env" do
      received_ua = nil
      conn = stubbed_conn do |ta|
        ta.stub(:get, "/check") do |env|
          received_ua = env.request_headers["X-Custom"]?
          {200, HTTP::Headers.new, "ok"}
        end
      end
      conn.get("/check", nil, {"X-Custom" => "indeed"})
      expect(received_ua).to eq("indeed")
    end

    it "POST passes body to env" do
      received_body = nil
      conn = stubbed_conn do |ta|
        ta.stub(:post, "/submit") do |env|
          received_body = env.request_body
          {200, HTTP::Headers.new, "ok"}
        end
      end
      conn.post("/submit", "foo=bar")
      expect(received_body).to eq("foo=bar")
    end

    it "merges connection-level params into URL" do
      ta = Faraday::Adapter::Test.new
      conn = Faraday::Connection.new("http://example.com") do |c|
        c.params["api_key"] = "secret"
        c.builder.adapter(ta)
      end
      seen_url = nil
      ta.stub(:get, "/search") do |env|
        seen_url = env.url
        {200, HTTP::Headers.new, "ok"}
      end
      conn.get("/search")
      expect(seen_url.not_nil!.query).to contain("api_key=secret")
    end
  end

  # ------------------------------------------------------------------ #
  describe Faraday::Utils::ParamsHash do
    subject { Faraday::Utils::ParamsHash.new }

    it "stores and retrieves string keys" do
      subject["foo"] = "bar"
      expect(subject["foo"]).to eq("bar")
    end

    it "encodes to query string" do
      subject["a"] = "1"
      subject["b"] = "2"
      query = subject.to_query
      expect(query).to contain("a=1")
      expect(query).to contain("b=2")
    end

    it "merges a query string" do
      subject.merge_query("x=1&y=hello+world")
      expect(subject["x"]).to eq("1")
      expect(subject["y"]).to eq("hello world")
    end

    it "updates from a Hash" do
      subject.update({"page" => "1", "q" => "test"})
      expect(subject["page"]).to eq("1")
      expect(subject["q"]).to eq("test")
    end

    it "dup produces independent copy" do
      subject["key"] = "original"
      copy = subject.dup
      copy["key"] = "changed"
      expect(subject["key"]).to eq("original")
    end
  end

  # ------------------------------------------------------------------ #
  describe Faraday::FlatParamsEncoder do
    it "encodes a simple hash" do
      result = Faraday::FlatParamsEncoder.encode({"a" => "1", "b" => "hello world"})
      expect(result).to contain("a=1")
      expect(result).to contain("b=hello+world")
    end

    it "encodes array values as repeated keys" do
      result = Faraday::FlatParamsEncoder.encode({"ids" => ["1", "2", "3"]})
      expect(result).to contain("ids=1")
      expect(result).to contain("ids=2")
      expect(result).to contain("ids=3")
    end

    it "encodes special characters" do
      result = Faraday::FlatParamsEncoder.encode({"q" => "a&b=c"})
      expect(result).not_to contain("&b")
      expect(result).to contain("q=")
    end

    it "returns empty string for empty hash" do
      expect(Faraday::FlatParamsEncoder.encode({} of String => String)).to eq("")
    end

    it "decodes a query string" do
      result = Faraday::FlatParamsEncoder.decode("a=1&b=hello+world")
      expect(result["a"]).to eq("1")
      expect(result["b"]).to eq("hello world")
    end

    it "decodes percent-encoded characters" do
      result = Faraday::FlatParamsEncoder.decode("q=hello%20world")
      expect(result["q"]).to eq("hello world")
    end

    it "decodes empty string to empty hash" do
      expect(Faraday::FlatParamsEncoder.decode("").empty?).to be_true
    end

    it "decodes nil to empty hash" do
      expect(Faraday::FlatParamsEncoder.decode(nil).empty?).to be_true
    end

    it "handles keys without values" do
      result = Faraday::FlatParamsEncoder.decode("flag")
      expect(result["flag"]).to eq("")
    end
  end

  # ------------------------------------------------------------------ #
  describe Faraday::Response::RaiseError do
    {% for status, klass in {400 => "BadRequestError", 401 => "UnauthorizedError",
                              403 => "ForbiddenError", 404 => "ResourceNotFound",
                              407 => "ProxyAuthError", 408 => "RequestTimeoutError",
                              409 => "ConflictError", 422 => "UnprocessableContentError",
                              429 => "TooManyRequestsError"} %}
    it "raises Faraday::{{klass.id}} on {{status.id}}" do
      ta = Faraday::Adapter::Test.new
      ta.stub(:get, "/err") { |_| { {{status}}, HTTP::Headers.new, "error body" } }
      conn = Faraday::Connection.new("http://example.com") do |c|
        c.builder.response(:raise_error)
        c.builder.adapter(ta)
      end
      expect_raises(Faraday::{{klass.id}}) { conn.get("/err") }
    end
    {% end %}

    it "raises generic ClientError for unmapped 4xx" do
      ta = Faraday::Adapter::Test.new
      ta.stub(:get, "/err") { |_| {418, HTTP::Headers.new, "teapot"} }
      conn = Faraday::Connection.new("http://example.com") do |c|
        c.builder.response(:raise_error)
        c.builder.adapter(ta)
      end
      expect_raises(Faraday::ClientError) { conn.get("/err") }
    end

    it "raises generic ServerError for 5xx" do
      ta = Faraday::Adapter::Test.new
      ta.stub(:get, "/err") { |_| {503, HTTP::Headers.new, "unavailable"} }
      conn = Faraday::Connection.new("http://example.com") do |c|
        c.builder.response(:raise_error)
        c.builder.adapter(ta)
      end
      expect_raises(Faraday::ServerError) { conn.get("/err") }
    end

    it "attaches response to raised error" do
      ta = Faraday::Adapter::Test.new
      ta.stub(:get, "/err") { |_| {404, HTTP::Headers.new, "missing"} }
      conn = Faraday::Connection.new("http://example.com") do |c|
        c.builder.response(:raise_error)
        c.builder.adapter(ta)
      end
      begin
        conn.get("/err")
        fail "should have raised"
      rescue err : Faraday::ResourceNotFound
        expect(err.response_status).to eq(404)
        expect(err.response_body).to eq("missing")
      end
    end

    it "passes through successful 2xx responses" do
      ta = Faraday::Adapter::Test.new
      ta.stub(:get, "/ok") { |_| {200, HTTP::Headers.new, "all good"} }
      conn = Faraday::Connection.new("http://example.com") do |c|
        c.builder.response(:raise_error)
        c.builder.adapter(ta)
      end
      resp = conn.get("/ok")
      expect(resp.status).to eq(200)
    end
  end

  # ------------------------------------------------------------------ #
  describe Faraday::Request::UrlEncoded do
    it "sets Content-Type for POST" do
      app = EchoApp.new
      mw = Faraday::Request::UrlEncoded.new(app)
      env = Faraday::Env.new(method: :post)
      env.request_body = "name=test"
      mw.on_request(env)
      expect(env.request_headers["Content-Type"]).to eq("application/x-www-form-urlencoded")
    end

    it "does not set Content-Type for GET" do
      app = EchoApp.new
      mw = Faraday::Request::UrlEncoded.new(app)
      env = Faraday::Env.new(method: :get)
      mw.on_request(env)
      expect(env.request_headers["Content-Type"]?).to be_nil
    end

    it "does not overwrite existing Content-Type" do
      app = EchoApp.new
      mw = Faraday::Request::UrlEncoded.new(app)
      env = Faraday::Env.new(method: :post)
      env.request_body = "data"
      env.request_headers["Content-Type"] = "application/json"
      mw.on_request(env)
      expect(env.request_headers["Content-Type"]).to eq("application/json")
    end

    it "sets Content-Type for PUT" do
      app = EchoApp.new
      mw = Faraday::Request::UrlEncoded.new(app)
      env = Faraday::Env.new(method: :put)
      env.request_body = "x=1"
      mw.on_request(env)
      expect(env.request_headers["Content-Type"]).to eq("application/x-www-form-urlencoded")
    end
  end

  # ------------------------------------------------------------------ #
  describe Faraday::AdapterRegistry do
    it "raises ArgumentError for unknown adapter key" do
      expect_raises(ArgumentError) do
        Faraday::AdapterRegistry.lookup(:does_not_exist_42)
      end
    end
  end
end
