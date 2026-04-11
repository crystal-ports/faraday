module Faraday
  class Adapter
    # Test adapter for use in specs. Stubs HTTP requests.
    class Test < Adapter
      alias StubProc = Proc(Env, Tuple(Int32, Hash(String, String), String))

      # Stubs holds a collection of stubbed HTTP request/response pairs.
      class Stubs
        class NotFound < Faraday::Error; end

        @stubs : Array(Tuple(Symbol, String | Regex, String?, StubProc))
        @strict_mode : Bool

        def initialize(strict_mode : Bool = false, &block : Stubs ->)
          @stubs = [] of Tuple(Symbol, String | Regex, String?, StubProc)
          @strict_mode = strict_mode
          block.call(self)
        end

        def add_raw(method : Symbol, path : String | Regex, body : String?, proc : StubProc)
          @stubs << {method, path.as(String | Regex), body, proc}
        end

        {% for method in [:get, :post, :put, :delete, :head, :patch, :options] %}
          def {{method.id}}(path : String, body : String? = nil, &block : Env -> Tuple(Int32, Hash(String, String), String))
            @stubs << { :{{method.id}}, path.as(String | Regex), body, block.as(StubProc) }
          end

          def {{method.id}}(path : Regex, body : String? = nil, &block : Env -> Tuple(Int32, Hash(String, String), String))
            @stubs << { :{{method.id}}, path.as(String | Regex), body, block.as(StubProc) }
          end
        {% end %}

        def match(method : Symbol, env : Env) : StubProc
          path = env.url.try(&.path) || "/"
          query = env.url.try(&.query)
          request_body = env.request_body

          body_str = case request_body
                     when String    then request_body.as(String)
                     when JSON::Any then request_body.as(JSON::Any).to_json
                     else               nil
                     end

          found = @stubs.find do |m, p, b, _|
            next false unless m == method

            path_match = case p
                         when String
                           if @strict_mode
                             full = query ? "#{path}?#{query}" : path
                             p == full
                           else
                             p == path
                           end
                         when Regex
                           p === path
                         else
                           false
                         end
            next false unless path_match

            b.nil? || b == body_str
          end

          raise NotFound.new("No stub for #{method.to_s.upcase} #{path}") unless found
          found.not_nil![3]
        end
      end

      def initialize(_app : Handler? = nil)
        @stubs = Stubs.new { }
      end

      def initialize(_app : Handler? = nil, stubs : Stubs = Stubs.new { })
        @stubs = stubs
      end

      # Old-style direct stub registration (accepts HTTP::Headers, converts to Hash).
      def stub(method : Symbol, path : String, &block : Env -> Tuple(Int32, HTTP::Headers, String))
        wrapped = ->(env : Env) : Tuple(Int32, Hash(String, String), String) {
          r = block.call(env)
          hash = {} of String => String
          r[1].each { |k, vs| hash[k] = vs.first? || "" }
          {r[0].as(Int32), hash.as(Hash(String, String)), r[2].as(String)}
        }
        @stubs.add_raw(method, path, nil, wrapped)
      end

      def call(env : Env) : Response
        block = @stubs.match(env.method, env)
        status, headers_hash, body = block.call(env)
        headers = HTTP::Headers.new
        headers_hash.each { |k, v| headers[k] = v }
        save_response(env, status, body, headers)
      end
    end
  end
end

Faraday::AdapterRegistry.register(:test, Faraday::Adapter::Test)
