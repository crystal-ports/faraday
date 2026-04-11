require "../spec_helper"

# Crystal's AdapterRegistry is class-based, not instance-based like Ruby's.
# It exposes .register(key, klass) and .lookup(key) class methods.
# The Ruby API (instance .get/.set, string/constant lookup) does not exist in Crystal.

Spectator.describe Faraday::AdapterRegistry do
  describe ".lookup" do
    it "raises ArgumentError for an unregistered adapter" do
      expect { Faraday::AdapterRegistry.lookup(:nonexistent_zzz_adapter) }.to raise_error(ArgumentError)
    end
  end

  describe ".register and .lookup" do
    it "retrieves a registered adapter class" do
      # Adapter::Test registers itself when spec_helper requires it
      klass = Faraday::AdapterRegistry.lookup(:test)
      expect(klass == Faraday::Adapter::Test).to be_true
    end

    it "raises ArgumentError when adapter is not registered" do
      expect { Faraday::AdapterRegistry.lookup(:this_does_not_exist) }.to raise_error(ArgumentError)
    end
  end

  describe "Ruby instance-based API (get/set)" do
    pending "Ruby's instance-based get/set API is not ported to Crystal" do
      # Ruby: registry = Faraday::AdapterRegistry.new; registry.get(:SymName)
      # Crystal: Faraday::AdapterRegistry.lookup(:sym_name) (class method only)
    end
  end

  describe "string constant lookup" do
    pending "Ruby's const_get-based string lookup is not ported to Crystal" do
      # Ruby: registry.get('Faraday::Connection') looks up via const_get
      # Crystal: type-safe Symbol lookup only
    end
  end
end
