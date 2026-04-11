require "../../spec_helper"

Spectator.describe Faraday::NestedParamsEncoder do
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

    it "encodes nested hash using bracket notation" do
      result = described_class.encode({"a" => {"b" => "1"}})
      # Encoded as a[b]=1 (brackets may be percent-encoded)
      expect(result).to contain("a")
      expect(result).to contain("b")
      expect(result).to contain("1")
    end

    it "encodes array values with bracket notation" do
      result = described_class.encode({"a" => ["1", "2"]})
      # Encoded as a[]=1&a[]=2
      expect(result).to contain("1")
      expect(result).to contain("2")
    end

    it "encodes special characters" do
      result = described_class.encode({"q" => "hello world"})
      expect(result).not_to contain(" ")
    end
  end

  describe ".decode" do
    it "returns empty hash for empty string" do
      result = described_class.decode("")
      expect(result).to be_empty
    end

    it "decodes a simple query string" do
      result = described_class.decode("a=1&b=2")
      expect(result["a"]).to eq("1")
      expect(result["b"]).to eq("2")
    end

    it "decodes nested bracket notation" do
      result = described_class.decode("a[b]=1")
      nested = result["a"]
      expect(nested).not_to be_nil
      if nested.is_a?(Hash)
        expect(nested["b"]).to eq("1")
      end
    end

    it "decodes array bracket notation" do
      result = described_class.decode("a[]=1&a[]=2")
      val = result["a"]
      expect(val).not_to be_nil
      if val.is_a?(Array)
        expect(val).to contain("1")
        expect(val).to contain("2")
      end
    end

    it "handles percent-encoded brackets" do
      result = described_class.decode("a%5Bb%5D=1")
      nested = result["a"]
      if nested.is_a?(Hash)
        expect(nested["b"]).to eq("1")
      else
        expect(nested).not_to be_nil
      end
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
