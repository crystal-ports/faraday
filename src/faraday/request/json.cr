module Faraday
  class Request
    # Middleware that JSON-encodes request bodies for POST/PUT/PATCH requests.
    class Json < Middleware
      CONTENT_TYPE = "Content-Type"
      MIME_TYPE    = "application/json"

      def on_request(env : Env)
        return unless Env::METHODS_WITH_BODIES.includes?(env.method)
        body = env.request_body
        return if body.nil?
        return if body.is_a?(String)
        env.request_headers[CONTENT_TYPE] ||= MIME_TYPE
        env.request_body = body.to_json
      end
    end
  end
end

