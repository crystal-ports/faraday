require "../spec_helper"

# Crystal's MiddlewareRegistry uses module-level class variables (@@registered).
# Unlike Ruby where each class that extends the module gets its own registry,
# Crystal shares the registry at module level. Tests run against Faraday::Middleware.

Spectator.describe Faraday::MiddlewareRegistry do
  let(test_key) { :__spectator_test_mw_key__ }

  after_each {
    begin
      Faraday::Middleware.unregister_middleware(test_key)
    rescue
    end
  }

  describe "#register_middleware" do
    it "registers a middleware class by symbol key" do
      Faraday::Middleware.register_middleware(test_key, Faraday::Middleware)
      expect(Faraday::Middleware.lookup_middleware(test_key)).to eq(Faraday::Middleware)
    end

    it "allows registering multiple keys at once" do
      key2 = :__spectator_test_mw_key2__
      Faraday::Middleware.register_middleware(test_key, Faraday::Middleware)
      Faraday::Middleware.register_middleware(key2, Faraday::Middleware)
      expect(Faraday::Middleware.lookup_middleware(test_key)).to eq(Faraday::Middleware)
      expect(Faraday::Middleware.lookup_middleware(key2)).to eq(Faraday::Middleware)
      Faraday::Middleware.unregister_middleware(key2) rescue nil
    end
  end

  describe "#lookup_middleware" do
    it "raises Faraday::Error for an unknown key" do
      expect { Faraday::Middleware.lookup_middleware(:totally_unknown_key_zzz_xyz) }.to raise_error(Faraday::Error)
    end

    it "returns the registered class" do
      Faraday::Middleware.register_middleware(test_key, Faraday::Middleware)
      klass = Faraday::Middleware.lookup_middleware(test_key)
      expect(klass).to eq(Faraday::Middleware)
    end
  end

  describe "#unregister_middleware" do
    it "removes a registered middleware" do
      Faraday::Middleware.register_middleware(test_key, Faraday::Middleware)
      Faraday::Middleware.unregister_middleware(test_key)
      expect { Faraday::Middleware.lookup_middleware(test_key) }.to raise_error(Faraday::Error)
    end
  end

  describe "#registered_middleware" do
    it "returns the registry hash" do
      Faraday::Middleware.register_middleware(test_key, Faraday::Middleware)
      registry = Faraday::Middleware.registered_middleware
      expect(registry).to be_a(Hash(Symbol, Faraday::Handler.class))
      expect(registry[test_key]).to eq(Faraday::Middleware)
    end
  end

  describe "Ruby-style per-class registry" do
    pending "In Ruby, each class that extends MiddlewareRegistry gets its own registry; Crystal shares at module level" do
    end
  end
end
