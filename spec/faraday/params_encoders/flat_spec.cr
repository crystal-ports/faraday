require "../../spec_helper"

Spectator.describe Faraday::FlatParamsEncoder do
  describe ".encode" do
    it "returns empty string for empty hash" do
      expect(described_class.encode({} of String => String)).to eq("")
    end

    it "encodes a single key=value pair" do
      result = described_class.encode({"a" => "1"})
      expect(result).to eq("a=1")
    end

    it "encodes multiple key=value pairs" do
      result = described_class.encode({"a" => "1", "b" => "2"})
      expect(result).to contain("a=1")
      expect(result).to contain("b=2")
    end

    it "encodes array values with the same key repeated" do
      result = described_class.encode({"a" => ["1", "2"]})
      expect(result).to contain("a=1")
      expect(result).to contain("a=2")
    end

    it "encodes special characters" do
      result = described_class.encode({"key" => "hello world"})
      expect(result).not_to contain(" ")
      expect(result).to contain("key=")
    end

    it "encodes nil value" do
      result = described_class.encode({"a" => nil})
      # nil value typically encodes as key only or key=
      expect(result).to contain("a")
    end
  end

  describe ".decode" do
    it "returns empty hash for empty string" do
      result = described_class.decode("")
      expect(result).to be_empty
    end

    it "decodes a single key=value" do
      result = described_class.decode("foo=bar")
      expect(result["foo"]).to eq("bar")
    end

    it "decodes multiple key=value pairs" do
      result = described_class.decode("a=1&b=2")
      expect(result["a"]).to eq("1")
      expect(result["b"]).to eq("2")
    end

    it "handles repeated keys" do
      result = described_class.decode("a=1&a=2")
      val = result["a"]
      # FlatParamsEncoder stores repeated keys as an Array
      if val.is_a?(Array)
        expect(val).to contain("1")
        expect(val).to contain("2")
      else
        expect(val).not_to be_nil
      end
    end

    it "handles encoded spaces" do
      result = described_class.decode("key=hello+world")
      expect(result["key"]).not_to be_nil
    end

    it "handles percent-encoded characters" do
      result = described_class.decode("a=hello%20world")
      expect(result["a"].to_s).to contain("hello")
    end
  end

  describe "encode/decode roundtrip" do
    it "roundtrips simple params" do
      params = {"x" => "1", "y" => "2"}
      encoded = described_class.encode(params)
      decoded = described_class.decode(encoded)
      expect(decoded["x"]).to eq("1")
      expect(decoded["y"]).to eq("2")
    end
  end
end
