require "../../spec_helper"

Spectator.describe Faraday::ProxyOptions do
  describe ".from with a string URL" do
    let(proxy_url) { "http://proxy.example.com:8080" }
    subject { Faraday::ProxyOptions.from(proxy_url) }

    it "creates a ProxyOptions" do
      expect(subject).not_to be_nil
    end

    it "parses the host" do
      expect(subject.not_nil!.uri.not_nil!.host).to eq("proxy.example.com")
    end

    it "parses the port" do
      expect(subject.not_nil!.uri.not_nil!.port).to eq(8080)
    end
  end

  describe ".from with credentials in URL" do
    let(proxy_url) { "http://user:pass@proxy.example.com:80" }
    subject { Faraday::ProxyOptions.from(proxy_url) }

    it "extracts the user" do
      expect(subject.not_nil!.user).to eq("user")
    end

    it "extracts the password" do
      expect(subject.not_nil!.password).to eq("pass")
    end

    it "parses the host" do
      expect(subject.not_nil!.uri.not_nil!.host).to eq("proxy.example.com")
    end
  end

  describe ".from with nil" do
    it "returns nil" do
      expect(Faraday::ProxyOptions.from(nil)).to be_nil
    end
  end

  describe ".from with URI" do
    let(proxy_uri) { URI.parse("http://proxy.example.com:3128") }
    subject { Faraday::ProxyOptions.from(proxy_uri) }

    it "creates a ProxyOptions" do
      expect(subject).not_to be_nil
    end

    it "has the correct host" do
      expect(subject.not_nil!.uri.not_nil!.host).to eq("proxy.example.com")
    end

    it "has the correct port" do
      expect(subject.not_nil!.uri.not_nil!.port).to eq(3128)
    end
  end

  describe "properties" do
    subject { Faraday::ProxyOptions.new }

    it "user defaults to nil" do
      expect(subject.user).to be_nil
    end

    it "password defaults to nil" do
      expect(subject.password).to be_nil
    end

    it "uri defaults to nil" do
      expect(subject.uri).to be_nil
    end

    it "allows setting user" do
      subject.user = "myuser"
      expect(subject.user).to eq("myuser")
    end

    it "allows setting password" do
      subject.password = "mypass"
      expect(subject.password).to eq("mypass")
    end
  end

  describe ".from with Hash" do
    pending "ProxyOptions.from(Hash) may not be ported to Crystal" do
      # Ruby: Faraday::ProxyOptions.from(uri: 'http://proxy.com', user: 'u', password: 'p')
    end
  end
end
