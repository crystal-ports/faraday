module Faraday
  class Response
    # Middleware that passes JSON responses through (body remains as the raw JSON string).
    # In Crystal, response body stays as String; JSON parsing is left to the caller.
    class Json < Faraday::Middleware
      def on_complete(env : Env)
        # Leave body unchanged; the raw JSON string is already accessible.
      end
    end
  end
end

