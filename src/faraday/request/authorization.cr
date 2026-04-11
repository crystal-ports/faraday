module Faraday
  class Request
    # Middleware that adds an Authorization header to requests.
    class Authorization < Middleware
      AUTH_HEADER = "Authorization"

      def initialize(@app : Handler, @header_value : String)
      end

      def on_request(env : Env)
        env.request_headers[AUTH_HEADER] ||= @header_value
      end
    end
  end
end

