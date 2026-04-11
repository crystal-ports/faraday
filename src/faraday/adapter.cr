module Faraday
  # Adapter is the base class for HTTP adapters. Adapters are the bottom
  # of the middleware stack and make the actual HTTP requests.
  abstract class Adapter < Handler
    CONTENT_LENGTH = "Content-Length"

    # Adapters accept an optional upstream handler (ignored) for stack compat.
    def initialize(_app : Handler? = nil)
    end

    private def save_response(env : Env, status : Int32, body : String?,
                               headers : HTTP::Headers? = nil,
                               reason_phrase : String? = nil) : Response
      env.status = status
      env.response_body = body
      env.reason_phrase = reason_phrase.try(&.strip)

      response_headers = HTTP::Headers.new
      if h = headers
        h.each { |name, values| values.each { |v| response_headers.add(name, v) } }
      end
      env.response_headers = response_headers

      response = env.response || Response.new
      response.finish(env) unless env.parallel?
      env.response = response
      response
    end
  end
end

require "./adapter/net_http"
