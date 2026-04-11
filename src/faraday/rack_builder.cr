module Faraday
  # RackBuilder builds the middleware stack (Rack-inspired).
  class RackBuilder
    LOCK_ERR             = "can't modify middleware stack after making a request"
    MISSING_ADAPTER_ERROR = "An adapter must be set on the Faraday connection.\n" \
                            "Set Faraday.default_adapter or use the builder:\n" \
                            "  conn = Faraday.new { |f| f.adapter :net_http }"

    class StackLocked < Exception; end

    # Alias so specs can reference Faraday::RackBuilder::HandlerSpec
    alias HandlerSpec = Faraday::HandlerSpec

    getter handlers : Array(HandlerSpec)
    getter adapter_spec : AdapterSpec?

    @app : Handler?

    def initialize
      @handlers = [] of HandlerSpec
      @adapter_spec = nil
      @locked = false
      @app = nil
      set_default_adapter
    end

    def initialize(&block : RackBuilder ->)
      @handlers = [] of HandlerSpec
      @adapter_spec = nil
      @locked = false
      @app = nil
      block.call(self)
      set_default_adapter unless @adapter_spec
    end

    # Add a middleware class to the stack.
    macro use(klass)
      use_handler({{klass}}, {{klass}}.name, ->(app : Faraday::Handler) { {{klass}}.new(app).as(Faraday::Handler) })
    end

    def use_handler(klass, name : String, factory : Handler -> Handler)
      raise_if_locked
      @handlers << HandlerSpec.new(name, factory)
    end

    # Add middleware by class directly (for runtime use).
    def use_class(klass : Request::UrlEncoded.class)
      raise_if_locked
      @handlers << HandlerSpec.new("Faraday::Request::UrlEncoded",
        ->(app : Handler) { Request::UrlEncoded.new(app).as(Handler) })
    end

    def use_class(klass : Request::Json.class)
      raise_if_locked
      @handlers << HandlerSpec.new("Faraday::Request::Json",
        ->(app : Handler) { Request::Json.new(app).as(Handler) })
    end

    def use_class(klass : Response::RaiseError.class)
      raise_if_locked
      @handlers << HandlerSpec.new("Faraday::Response::RaiseError",
        ->(app : Handler) { Response::RaiseError.new(app).as(Handler) })
    end

    def use_class(klass : Response::Json.class)
      raise_if_locked
      @handlers << HandlerSpec.new("Faraday::Response::Json",
        ->(app : Handler) { Response::Json.new(app).as(Handler) })
    end

    # Add middleware by symbol key.
    def request(key : Symbol)
      raise_if_locked
      case key
      when :url_encoded
        use_class(Request::UrlEncoded)
      when :json
        use_class(Request::Json)
      else
        raise Faraday::Error.new("Unknown request middleware: #{key.inspect}")
      end
    end

    # :authorization with symbol type (:basic requires user+pass, :token requires token)
    def request(key : Symbol, auth_type : Symbol, user : String, pass : String)
      raise_if_locked
      case key
      when :authorization
        case auth_type
        when :basic
          value = Utils.basic_header_from(user, pass)
          @handlers << HandlerSpec.new("Faraday::Request::Authorization",
            ->(app : Handler) { Request::Authorization.new(app, value).as(Handler) })
        when :token
          @handlers << HandlerSpec.new("Faraday::Request::Authorization",
            ->(app : Handler) { Request::Authorization.new(app, "Token #{user}").as(Handler) })
        else
          raise Faraday::Error.new("Unknown authorization type: #{auth_type}")
        end
      else
        raise Faraday::Error.new("Unknown request middleware: #{key.inspect}")
      end
    end

    def request(key : Symbol, auth_type : Symbol, token : String)
      raise_if_locked
      case key
      when :authorization
        case auth_type
        when :token
          @handlers << HandlerSpec.new("Faraday::Request::Authorization",
            ->(app : Handler) { Request::Authorization.new(app, "Token #{token}").as(Handler) })
        else
          raise Faraday::Error.new("Unknown authorization type: #{auth_type}")
        end
      else
        raise Faraday::Error.new("Unknown request middleware: #{key.inspect}")
      end
    end

    def request(key : Symbol, auth_type : String, token : String)
      raise_if_locked
      case key
      when :authorization
        @handlers << HandlerSpec.new("Faraday::Request::Authorization",
          ->(app : Handler) { Request::Authorization.new(app, "#{auth_type} #{token}").as(Handler) })
      else
        raise Faraday::Error.new("Unknown request middleware: #{key.inspect}")
      end
    end

    def response(key : Symbol, *, allowed_statuses : Array(Int32) = [] of Int32)
      raise_if_locked
      case key
      when :raise_error
        statuses = allowed_statuses
        @handlers << HandlerSpec.new("Faraday::Response::RaiseError",
          ->(app : Handler) { Response::RaiseError.new(app, statuses).as(Handler) })
      when :json
        use_class(Response::Json)
      else
        raise Faraday::Error.new("Unknown response middleware: #{key.inspect}")
      end
    end

    # Set the adapter by symbol (no stubs).
    def adapter(key : Symbol)
      raise_if_locked
      case key
      when :net_http
        @adapter_spec = AdapterSpec.new("Faraday::Adapter::NetHttp",
          -> { Adapter::NetHttp.new.as(Handler) })
      when :test
        @adapter_spec = AdapterSpec.new("Faraday::Adapter::Test",
          -> { Adapter::Test.new.as(Handler) })
      else
        raise ArgumentError.new("Unknown adapter: #{key.inspect}")
      end
    end

    # Set the adapter by symbol with stubs (for Test adapter).
    def adapter(key : Symbol, stubs : Adapter::Test::Stubs)
      raise_if_locked
      case key
      when :test
        @adapter_spec = AdapterSpec.new("Faraday::Adapter::Test",
          -> { Adapter::Test.new(nil, stubs).as(Handler) })
      else
        raise ArgumentError.new("Adapter #{key.inspect} does not accept stubs")
      end
    end

    # Set the adapter by symbol with keyword opts (legacy compat).
    def adapter(key : Symbol, **opts)
      adapter(key)
    end

    # Set the adapter by class.
    def adapter(klass : Adapter::NetHttp.class, **opts)
      @adapter_spec = AdapterSpec.new("Faraday::Adapter::NetHttp",
        -> { Adapter::NetHttp.new.as(Handler) })
    end

    # Set the adapter from a pre-built instance (useful for tests and custom adapters).
    def adapter(instance : Adapter)
      @adapter_spec = AdapterSpec.new(instance.class.name,
        -> { instance.as(Handler) })
    end

    # Lock the stack, preventing further modifications.
    def lock!
      @locked = true
    end

    def locked? : Bool
      @locked
    end

    # Get or build the app (locks the stack on first call).
    def app : Handler
      @app ||= begin
        lock!
        raise StackLocked.new(MISSING_ADAPTER_ERROR) unless @adapter_spec
        to_app
      end
    end

    # Build the middleware chain and return the outermost handler.
    def to_app : Handler
      base = @adapter_spec.not_nil!.build
      @handlers.reverse.reduce(base) { |inner, spec| spec.build(inner) }
    end

    # Build a Faraday::Response from a connection and request.
    def build_response(connection : Connection, request : Request) : Response
      env = build_env(connection, request)
      app.call(env)
    end

    def build_env(connection : Connection, request : Request) : Env
      exclusive_url = connection.build_exclusive_url(
        request.path, request.params, request.options
      )

      env = Env.new(
        method: request.http_method,
        request_body: request.body,
        url: exclusive_url,
        request: request.options,
        request_headers: request.headers,
        ssl: connection.ssl,
      )
      env
    end

    private def raise_if_locked
      raise StackLocked.new(LOCK_ERR) if locked?
    end

    private def set_default_adapter
      adapter(Faraday.default_adapter)
    end
  end
end
