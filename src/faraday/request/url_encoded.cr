module Faraday
  class Request
    # Middleware that URL-encodes request bodies for POST/PUT/PATCH requests.
    class UrlEncoded < Middleware
      CONTENT_TYPE = "Content-Type"
      MIME_TYPE    = "application/x-www-form-urlencoded"

      def on_request(env : Env)
        return unless process_request?(env)
        env.request_headers[CONTENT_TYPE] ||= MIME_TYPE
        env.request_body = encode_body(env.request_body)
      end

      private def process_request?(env : Env) : Bool
        return false unless Env::METHODS_WITH_BODIES.includes?(env.method)
        body = env.request_body
        body.is_a?(String) || (body.is_a?(JSON::Any) && !body.as_h?.nil?)
      end

      private def encode_body(body : JSON::Any | String | Nil) : String
        case body
        when JSON::Any
          if h = body.as_h?
            h.map { |k, v|
              "#{URI.encode_www_form(k)}=#{URI.encode_www_form(v.as_s? || v.to_s)}"
            }.join("&")
          else
            body.to_s
          end
        when String
          body
        else
          ""
        end
      end
    end
  end
end
