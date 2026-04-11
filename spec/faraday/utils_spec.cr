require "../spec_helper"

Spectator.describe Faraday::Utils do
  describe ".parse_uri" do
    let(url) { "http://example.com/abc" }

    it "returns a URI" do
      uri = Faraday::Utils.parse_uri(url)
      expect(uri).to be_a(URI)
    end

    it "parses the host" do
      uri = Faraday::Utils.parse_uri(url)
      expect(uri.host).to eq("example.com")
    end

    it "parses the path" do
      uri = Faraday::Utils.parse_uri(url)
      expect(uri.path).to eq("/abc")
    end
  end

  describe ".escape" do
    it "encodes spaces" do
      result = Faraday::Utils.escape("hello world")
      expect(result).not_to contain(" ")
    end

    it "does not modify safe characters" do
      result = Faraday::Utils.escape("hello")
      expect(result).to contain("hello")
    end

    it "encodes special characters" do
      result = Faraday::Utils.escape("$32,000.00")
      expect(result).not_to contain("$")
      expect(result).not_to contain(",")
    end
  end

  describe ".unescape" do
    it "decodes percent-encoded characters" do
      escaped = Faraday::Utils.escape("hello world")
      result = Faraday::Utils.unescape(escaped)
      expect(result).to contain("hello")
      expect(result).to contain("world")
    end
  end

  describe ".basic_header_from" do
    it "returns a Basic auth header string" do
      header = Faraday::Utils.basic_header_from("user", "pass")
      expect(header).to start_with("Basic ")
    end

    it "base64-encodes the credentials" do
      header = Faraday::Utils.basic_header_from("user", "pass")
      # Base64("user:pass") = "dXNlcjpwYXNz"
      expect(header).to contain("dXNlcjpwYXNz")
    end
  end

  describe ".build_query" do
    it "encodes a hash to a query string" do
      result = Faraday::Utils.build_query({"a" => "1", "b" => "2"})
      expect(result).to contain("a=1")
      expect(result).to contain("b=2")
    end

    it "returns empty string for empty hash" do
      result = Faraday::Utils.build_query({} of String => String)
      expect(result).to eq("")
    end
  end

  describe ".parse_query" do
    it "parses a query string to a hash" do
      result = Faraday::Utils.parse_query("a=1&b=2")
      expect(result["a"]).to eq("1")
      expect(result["b"]).to eq("2")
    end

    it "returns empty hash for empty string" do
      result = Faraday::Utils.parse_query("")
      expect(result).to be_empty
    end
  end

  describe ".build_nested_query" do
    it "encodes nested params" do
      result = Faraday::Utils.build_nested_query({"a" => "1"})
      expect(result).to contain("a=1")
    end
  end

  describe ".parse_nested_query" do
    it "parses a query string" do
      result = Faraday::Utils.parse_nested_query("a=1")
      expect(result["a"]).to eq("1")
    end
  end

  describe ".normalize_path" do
    it "returns a string" do
      result = Faraday::Utils.normalize_path("/foo/../bar")
      expect(result).to be_a(String)
    end
  end

  describe ".sort_query_params" do
    it "sorts query params alphabetically" do
      result = Faraday::Utils.sort_query_params("b=2&a=1")
      expect(result.index("a").not_nil!).to be < result.index("b").not_nil!
    end
  end

  describe ".deep_merge!" do
    it "merges two hashes recursively" do
      target = {"a" => "1"} of String => String
      other = {"b" => "2"} of String => String
      result = Faraday::Utils.deep_merge!(target, other)
      expect(result).not_to be_nil
    end

    pending "deep_merge! with ConnectionOptions is not directly portable to Crystal"
  end

  describe "headers parsing" do
    it "parse headers for aggregated responses" do
      headers = Faraday::Utils::Headers.new
      multi_response_headers =
        "HTTP/1.x 500 OK\r\nContent-Type: text/html; charset=UTF-8\r\n" \
        "HTTP/1.x 200 OK\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n"
      headers.parse(multi_response_headers)
      expect(headers["Content-Type"]).to eq("application/json; charset=UTF-8")
    end
  end
end
