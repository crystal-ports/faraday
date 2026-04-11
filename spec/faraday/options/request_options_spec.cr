require "../../spec_helper"

Spectator.describe Faraday::RequestOptions do
  subject { Faraday::RequestOptions.new }

  describe "#timeout" do
    it "defaults to nil" do
      expect(subject.timeout).to be_nil
    end

    it "allows setting a timeout" do
      subject.timeout = 30
      expect(subject.timeout).to eq(30)
    end
  end

  describe "#open_timeout" do
    it "defaults to nil" do
      expect(subject.open_timeout).to be_nil
    end

    it "allows setting open_timeout" do
      subject.open_timeout = 5
      expect(subject.open_timeout).to eq(5)
    end
  end

  describe "#read_timeout" do
    it "defaults to nil" do
      expect(subject.read_timeout).to be_nil
    end

    it "allows setting read_timeout" do
      subject.read_timeout = 10
      expect(subject.read_timeout).to eq(10)
    end
  end

  describe "#write_timeout" do
    it "defaults to nil" do
      expect(subject.write_timeout).to be_nil
    end

    it "allows setting write_timeout" do
      subject.write_timeout = 15
      expect(subject.write_timeout).to eq(15)
    end
  end

  describe "#boundary" do
    it "defaults to nil" do
      expect(subject.boundary).to be_nil
    end

    it "allows setting boundary" do
      subject.boundary = "test-boundary"
      expect(subject.boundary).to eq("test-boundary")
    end
  end

  describe "#params_encoder" do
    it "defaults to nil" do
      expect(subject.params_encoder).to be_nil
    end
  end

  pending "Ruby RequestOptions.new with keyword args is not ported to Crystal"
  pending "Ruby RequestOptions.from(hash) is not ported to Crystal"
  pending "Ruby RequestOptions#to_h / #merge / #update are not ported to Crystal"
end
