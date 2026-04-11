module Faraday
  # Middleware is the base class for all Faraday middleware.
  # Subclasses override on_request and/or on_complete for their behavior.
  class Middleware < Handler
    extend MiddlewareRegistry

    @@lock = Mutex.new

    getter app : Handler

    def initialize(@app : Handler)
    end

    def call(env : Env) : Response
      on_request(env)
      response = @app.call(env)
      response.on_complete { |e| on_complete(e) }
      response
    end

    def close
      @app.close
    end

    # Override in subclasses to process the request before sending.
    def on_request(env : Env)
    end

    # Override in subclasses to process the response after receiving.
    def on_complete(env : Env)
    end
  end
end
