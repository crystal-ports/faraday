require "../../spec_helper"

Spectator.describe Faraday::Adapter::Test do
  let(stubs) {
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/")             { {200, {"Content-Type" => "text/html"}, "<html/>"} }
      stub.get("/foo")          { {200, {"Content-Type" => "text/html"}, "a"} }
      stub.get("/foo-bar")      { {200, {"Content-Type" => "text/html"}, "a"} }
      stub.get("/sub/1")        { {200, {"Content-Type" => "text/html"}, "a"} }
      stub.get("/sub/2")        { {200, {"Content-Type" => "text/html"}, "b"} }
      stub.post("/bar", "baz")  { {200, {} of String => String, ""} }
      stub.get("/with_body", "optbody") { {200, {} of String => String, ""} }
      stub.get("/empty")        { {204, {} of String => String, ""} }
    end
  }

  let(conn) {
    Faraday::Connection.new do |builder|
      builder.adapter :test, stubs
    end
  }

  it "returns 200 for GET /" do
    expect(conn.get("/").status).to eq(200)
  end

  it "returns the correct body for GET /foo" do
    expect(conn.get("/foo").body).to eq("a")
  end

  it "returns the correct body for GET /foo-bar" do
    expect(conn.get("/foo-bar").body).to eq("a")
  end

  it "raises NotFound for an unknown path" do
    expect { conn.get("/unknown") }.to raise_error(Faraday::Adapter::Test::Stubs::NotFound)
  end

  it "raises NotFound when using wrong HTTP method" do
    expect { conn.post("/") }.to raise_error(Faraday::Adapter::Test::Stubs::NotFound)
  end

  it "matches POST with correct body" do
    expect(conn.post("/bar", "baz").status).to eq(200)
  end

  it "raises NotFound for POST with wrong body" do
    expect { conn.post("/bar", "wrong") }.to raise_error(Faraday::Adapter::Test::Stubs::NotFound)
  end

  it "matches GET /sub/1" do
    expect(conn.get("/sub/1").status).to eq(200)
  end

  it "matches GET /sub/2 with correct body" do
    expect(conn.get("/sub/2").body).to eq("b")
  end

  it "returns 204 for /empty" do
    expect(conn.get("/empty").status).to eq(204)
  end

  describe "response headers" do
    it "sets the Content-Type header" do
      response = conn.get("/")
      expect(response.headers["Content-Type"]).to eq("text/html")
    end
  end

  describe "is_a? checks" do
    it "is a Faraday::Adapter" do
      expect(Faraday::Adapter::Test < Faraday::Adapter).to be_true
    end
  end

  describe "strict mode" do
    let(strict_stubs) {
      Faraday::Adapter::Test::Stubs.new(strict_mode: true) do |stub|
        stub.get("/foo?query=true") { {200, {} of String => String, "strict"} }
        stub.get("/exact")          { {200, {} of String => String, "ok"} }
      end
    }

    let(strict_conn) {
      Faraday::Connection.new do |b|
        b.adapter :test, strict_stubs
      end
    }

    it "matches the exact path with query string in strict mode" do
      expect(strict_conn.get("/foo?query=true").status).to eq(200)
    end

    it "raises NotFound when strict path does not match (missing query)" do
      expect { strict_conn.get("/foo") }.to raise_error(Faraday::Adapter::Test::Stubs::NotFound)
    end

    it "matches exact path without query in strict mode" do
      expect(strict_conn.get("/exact").status).to eq(200)
    end
  end

  describe "regex path matching" do
    let(regex_stubs) {
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get(/\A\/sub/) { {200, {} of String => String, "matched"} }
      end
    }

    let(regex_conn) {
      Faraday::Connection.new do |b|
        b.adapter :test, regex_stubs
      end
    }

    pending "regex-based path matching in Stubs" do
      # Crystal stub matching with Regex may differ from Ruby
    end
  end

  describe "stubs verify!" do
    pending "stubs.verify! checks all stubs were called" do
      # Ruby: stubs.verify! raises if stubs were not used
    end
  end
end
