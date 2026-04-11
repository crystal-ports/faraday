require "http/client"

module Faraday
  class Adapter
    # Crystal stdlib HTTP::Client adapter for Faraday.
    # This is the default adapter replacing Ruby's Net::HTTP.
    class NetHttp < Adapter
      def initialize(_app : Handler? = nil, @connection_options : Hash(Symbol, String) = {} of Symbol => String)
      end

      def call(env : Env) : Response
        url = env.url.not_nil!

        env.clear_body if env.needs_body?
        env.response = Response.new

        http_response = with_client(url, env) do |client|
          request_target = build_request_target(url)
          headers = env.request_headers
          body = env.request_body
          body_str = body.is_a?(JSON::Any) ? body.to_json : body

          case env.method
          when :get
            client.get(request_target, headers)
          when :post
            client.post(request_target, headers, body_str || "")
          when :put
            client.put(request_target, headers, body_str || "")
          when :patch
            client.patch(request_target, headers, body_str || "")
          when :delete
            client.delete(request_target, headers)
          when :head
            client.head(request_target, headers)
          when :options
            client.exec("OPTIONS", request_target, headers)
          when :trace
            client.exec("TRACE", request_target, headers)
          else
            raise Faraday::Error.new("Unsupported HTTP method: #{env.method}")
          end
        end

        save_response(env, http_response.status_code, http_response.body,
          http_response.headers, http_response.status.description)
      end

      private def with_client(url : URI, env : Env, &block : HTTP::Client -> HTTP::Client::Response)
        client = HTTP::Client.new(url)
        configure_timeouts(client, env.request)
        begin
          yield client
        ensure
          client.close
        end
      end

      private def configure_timeouts(client : HTTP::Client, options : RequestOptions)
        if (t = options.timeout)
          client.read_timeout = t.seconds
          client.connect_timeout = t.seconds
        end
        if (rt = options.read_timeout)
          client.read_timeout = rt.seconds
        end
        if (ot = options.open_timeout)
          client.connect_timeout = ot.seconds
        end
        if (wt = options.write_timeout)
          client.write_timeout = wt.seconds
        end
      end

      private def build_request_target(url : URI) : String
        path = url.path.empty? ? "/" : url.path
        if (q = url.query)
          "#{path}?#{q}"
        else
          path
        end
      end
    end
  end
end
