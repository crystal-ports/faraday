module Faraday
  # AdapterRegistry registers and looks up adapter classes by name.
  class AdapterRegistry
    @@lock = Mutex.new
    @@adapters = {} of Symbol => Handler.class

    def self.register(key : Symbol, klass : Handler.class)
      @@lock.synchronize { @@adapters[key] = klass }
    end

    def self.lookup(key : Symbol) : Handler.class
      @@lock.synchronize { @@adapters[key]? } ||
        raise ArgumentError.new("Unknown adapter: #{key.inspect}")
    end
  end
end
