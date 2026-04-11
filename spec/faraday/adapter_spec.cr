require "../spec_helper"

Spectator.describe Faraday::Adapter do
  describe "default adapter" do
    it "is :net_http" do
      expect(Faraday.default_adapter).to eq(:net_http)
    end
  end

  describe "request_timeout" do
    # Crystal's Adapter does not expose request_timeout as a public/accessible method.
    pending "request_timeout(:read, opts) returns timeout value" do
      # Ruby: adapter.send(:request_timeout, :read, request_opts)
      # Crystal: private or not implemented
    end

    pending "request_timeout(:write, opts) returns timeout value" do
    end

    pending "request_timeout(:open, opts) returns open_timeout" do
    end
  end

  describe "as a base class" do
    it "Adapter::Test is a subclass of Faraday::Adapter" do
      expect(Faraday::Adapter::Test.new(Faraday::RackBuilder.new { |b| b.adapter :test }.app)).to be_a(Faraday::Adapter)
    end
  end
end
