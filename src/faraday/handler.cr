module Faraday
  # Abstract base class for middleware handlers and adapters.
  # All objects in the middleware stack must inherit from this.
  abstract class Handler
    abstract def call(env : Env) : Response

    def close
    end
  end

  # HandlerSpec stores a factory proc for building a Handler in the middleware stack.
  class HandlerSpec
    getter name : String

    def initialize(@name : String, @factory : Handler -> Handler)
    end

    def build(app : Handler) : Handler
      @factory.call(app)
    end
  end

  # AdapterSpec stores a factory proc for building an Adapter (the bottom of the stack).
  class AdapterSpec
    getter name : String

    def initialize(@name : String, @factory : -> Handler)
    end

    def build : Handler
      @factory.call
    end
  end
end
