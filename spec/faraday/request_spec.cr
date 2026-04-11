require "../spec_helper"

Spectator.describe Faraday::Request do
  let(conn) { Faraday::Connection.new("http://httpbin.org/") }
  subject { conn.build_request(:get) }

  describe "#http_method" do
    it "is set to :get" do
      expect(subject.http_method).to eq(:get)
    end
  end

  describe "#path" do
    it "is a String" do
      expect(subject.path).to be_a(String)
    end
  end

  describe "#headers" do
    it "is an HTTP::Headers" do
      expect(subject.headers).to be_a(HTTP::Headers)
    end

    it "allows getting/setting via []" do
      subject["X-Test-Header"] = "test-value"
      expect(subject["X-Test-Header"]).to eq("test-value")
    end
  end

  describe "#params" do
    it "is not nil" do
      expect(subject.params).not_to be_nil
    end
  end

  describe "#body" do
    it "defaults to nil" do
      expect(subject.body).to be_nil
    end

    it "allows setting body" do
      subject.body = "hello"
      expect(subject.body).to eq("hello")
    end
  end

  describe "#url" do
    it "sets the path" do
      subject.url("products")
      expect(subject.path).to contain("products")
    end

    it "sets path with extra params" do
      subject.url("search", {"q" => "crystal"})
      expect(subject.path).to contain("search")
    end
  end

  describe "#options" do
    it "is a RequestOptions" do
      expect(subject.options).to be_a(Faraday::RequestOptions)
    end
  end

  describe "building a POST request" do
    subject { conn.build_request(:post) }

    it "has http_method :post" do
      expect(subject.http_method).to eq(:post)
    end
  end
end
