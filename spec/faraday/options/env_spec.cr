require "../../spec_helper"

Spectator.describe Faraday::Env do
  subject { Faraday::Env.new }

  describe "#method" do
    it "defaults to :get" do
      expect(subject.method).to eq(:get)
    end

    it "can be changed" do
      subject.method = :post
      expect(subject.method).to eq(:post)
    end
  end

  describe "#request_headers" do
    it "is an HTTP::Headers" do
      expect(subject.request_headers).to be_a(HTTP::Headers)
    end

    it "allows setting headers" do
      subject.request_headers["Content-Type"] = "text/plain"
      expect(subject.request_headers["Content-Type"]).to eq("text/plain")
    end
  end

  describe "#url" do
    it "defaults to nil" do
      expect(subject.url).to be_nil
    end

    it "can be set to a URI" do
      subject.url = URI.parse("http://example.com")
      expect(subject.url.not_nil!.host).to eq("example.com")
    end
  end

  describe "#status" do
    it "defaults to nil" do
      expect(subject.status).to be_nil
    end

    it "can be set" do
      subject.status = 200
      expect(subject.status).to eq(200)
    end
  end

  describe "#reason_phrase" do
    it "defaults to nil" do
      expect(subject.reason_phrase).to be_nil
    end

    it "can be set" do
      subject.reason_phrase = "OK"
      expect(subject.reason_phrase).to eq("OK")
    end
  end

  describe "#request_body and #response_body" do
    it "request_body defaults to nil" do
      expect(subject.request_body).to be_nil
    end

    it "response_body defaults to nil" do
      expect(subject.response_body).to be_nil
    end

    it "allows setting request_body" do
      subject.request_body = "req"
      expect(subject.request_body).to eq("req")
    end

    it "allows setting response_body" do
      subject.response_body = "resp"
      expect(subject.response_body).to eq("resp")
    end
  end

  describe "#body" do
    context "when status is set (response phase)" do
      before_each {
        subject.status = 200
        subject.response_body = "response body"
      }

      it "returns response_body" do
        expect(subject.body).to eq("response body")
      end
    end

    context "when no status is set (request phase)" do
      before_each {
        subject.request_body = "request body"
      }

      it "returns request_body" do
        expect(subject.body).to eq("request body")
      end
    end

    context "when neither body is set" do
      it "returns nil" do
        expect(subject.body).to be_nil
      end
    end
  end

  describe "#success?" do
    it "returns true for 200" do
      subject.status = 200
      expect(subject.success?).to be_true
    end

    it "returns true for 201" do
      subject.status = 201
      expect(subject.success?).to be_true
    end

    it "returns true for 299" do
      subject.status = 299
      expect(subject.success?).to be_true
    end

    it "returns false for 400" do
      subject.status = 400
      expect(subject.success?).to be_false
    end

    it "returns false for 500" do
      subject.status = 500
      expect(subject.success?).to be_false
    end

    it "returns false for 301" do
      subject.status = 301
      expect(subject.success?).to be_false
    end
  end

  describe "#custom_members" do
    it "is a Hash(Symbol, String)" do
      expect(subject.custom_members).to be_a(Hash(Symbol, String))
    end

    it "starts empty" do
      expect(subject.custom_members).to be_empty
    end

    it "allows storing custom data" do
      subject.custom_members[:my_key] = "my_value"
      expect(subject.custom_members[:my_key]).to eq("my_value")
    end
  end

  describe "#needs_body?" do
    it "returns a Bool" do
      expect(subject.needs_body?).to be_a(Bool)
    end
  end

  describe "#parse_body?" do
    it "returns a Bool" do
      expect(subject.parse_body?).to be_a(Bool)
    end
  end

  describe "#parallel?" do
    it "returns false by default" do
      expect(subject.parallel?).to be_false
    end
  end

  describe "#stream_response?" do
    it "returns false by default" do
      expect(subject.stream_response?).to be_false
    end
  end

  describe "#request" do
    it "returns a RequestOptions" do
      expect(subject.request).to be_a(Faraday::RequestOptions)
    end
  end

  describe "#ssl" do
    it "returns an SSLOptions" do
      expect(subject.ssl).to be_a(Faraday::SSLOptions)
    end
  end

  describe "Env.from class method" do
    pending "Env.from is a Ruby-specific constructor that is not ported to Crystal" do
      # Ruby: Faraday::Env.from(method: :get, status: 200, ...)
      # Crystal: use Faraday::Env.new and set properties
    end
  end

  describe "arbitrary key access (env[:key])" do
    pending "Ruby Env supports env[:custom_key] for arbitrary access; Crystal uses custom_members hash" do
    end
  end
end
