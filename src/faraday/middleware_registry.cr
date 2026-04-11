module Faraday
  # MiddlewareRegistry provides lookup of middleware classes by Symbol key.
  module MiddlewareRegistry
    REGISTRY       = {} of Symbol => Handler.class
    REGISTRY_MUTEX = Mutex.new

    def register_middleware(**mappings)
      REGISTRY_MUTEX.synchronize do
        mappings.each { |key, klass| REGISTRY[key] = klass }
      end
    end

    def register_middleware(key : Symbol, klass : Handler.class)
      REGISTRY_MUTEX.synchronize { REGISTRY[key] = klass }
    end

    def unregister_middleware(key : Symbol)
      REGISTRY_MUTEX.synchronize { REGISTRY.delete(key) }
    end

    def lookup_middleware(key : Symbol) : Handler.class
      REGISTRY_MUTEX.synchronize { REGISTRY[key]? } ||
        raise(Faraday::Error.new("#{key.inspect} is not registered on #{self}"))
    end

    def registered_middleware : Hash(Symbol, Handler.class)
      REGISTRY
    end
  end
end
