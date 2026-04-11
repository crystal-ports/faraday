require "../../spec_helper"

Spectator.describe Faraday::Utils::Headers do
  subject { Faraday::Utils::Headers.new }

  context "when Content-Type is set to application/json" do
    before_each {
      subject["Content-Type"] = "application/json"
    }

    it "stores the key as-is" do
      expect(subject.keys.map(&.name)).to contain("Content-Type")
    end

    it "retrieves with exact case" do
      expect(subject["Content-Type"]).to eq("application/json")
    end

    it "retrieves with uppercase key" do
      expect(subject["CONTENT-TYPE"]).to eq("application/json")
    end

    it "retrieves with lowercase key" do
      expect(subject["content-type"]).to eq("application/json")
    end

    it "includes lowercase key" do
      expect(subject.includes?("content-type")).to be_true
    end
  end

  context "when Content-Type is set to application/xml" do
    before_each {
      subject["Content-Type"] = "application/xml"
    }

    it "retrieves with exact case" do
      expect(subject["Content-Type"]).to eq("application/xml")
    end

    it "retrieves with mixed case" do
      expect(subject["content-type"]).to eq("application/xml")
    end
  end

  describe "#fetch" do
    before_each {
      subject["Content-Type"] = "application/json"
    }

    it "fetches with exact key" do
      expect(subject.fetch("Content-Type")).to eq("application/json")
    end

    it "fetches case-insensitively" do
      expect(subject.fetch("CONTENT-TYPE")).to eq("application/json")
    end

    it "returns default when key missing" do
      expect(subject.fetch("X-Missing", "default")).to eq("default")
    end

    it "returns false default when key missing" do
      expect(subject.fetch("X-Missing", false)).to eq(false)
    end

    it "returns nil default when key missing" do
      expect(subject.fetch("X-Missing", nil)).to be_nil
    end

    it "calls block when key not found" do
      result = subject.fetch("X-Missing") { |k| "#{k} not found" }
      expect(result).to eq("X-Missing not found")
    end

    it "does not call block when key found" do
      block_called = false
      subject.fetch("Content-Type") { block_called = true; "" }
      expect(block_called).to be_false
    end

    it "raises KeyError when key not found and no default" do
      expect { subject.fetch("X-Missing") }.to raise_error(KeyError)
    end
  end

  describe "#delete" do
    before_each {
      subject["Content-Type"] = "application/json"
    }

    it "removes the header" do
      subject.delete("content-type")
      expect(subject.size).to eq(0)
    end

    it "returns the deleted value" do
      result = subject.delete("content-type")
      expect(result).to eq("application/json")
    end

    it "returns nil when deleting non-existent key" do
      expect(subject.delete("X-NonExistent")).to be_nil
    end
  end

  describe "#parse" do
    context "with standard HTTP response headers" do
      let(raw_headers) { "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n" }

      before_each { subject.parse(raw_headers) }

      it "extracts the Content-Type header" do
        expect(subject["Content-Type"]).to eq("text/html")
      end

      it "is accessible case-insensitively" do
        expect(subject["content-type"]).to eq("text/html")
      end
    end

    context "with header values containing colons" do
      let(raw_headers) { "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nLocation: http://httpbingo.org/\r\n\r\n" }

      before_each { subject.parse(raw_headers) }

      it "correctly parses Location header with URL value" do
        expect(subject["location"]).to eq("http://httpbingo.org/")
      end
    end

    context "with blank lines in headers" do
      let(raw_headers) { "HTTP/1.1 200 OK\r\n\r\nContent-Type: text/html\r\n\r\n" }

      before_each { subject.parse(raw_headers) }

      it "still parses Content-Type" do
        expect(subject["content-type"]).to eq("text/html")
      end
    end
  end

  describe "#size" do
    it "is zero for empty headers" do
      expect(subject.size).to eq(0)
    end

    it "reflects number of headers set" do
      subject["X-A"] = "1"
      subject["X-B"] = "2"
      expect(subject.size).to eq(2)
    end
  end

  describe "#keys" do
    it "returns all header names" do
      subject["Content-Type"] = "application/json"
      subject["Authorization"] = "Bearer token"
      expect(subject.keys.size).to eq(2)
    end
  end
end
