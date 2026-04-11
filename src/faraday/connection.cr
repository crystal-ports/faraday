module Faraday
  # Connection manages the default properties and middleware stack for HTTP requests.
  class Connection
    METHODS    = Set{:get, :post, :put, :delete, :head, :patch, :options, :trace}
    USER_AGENT = "Faraday v#{VERSION}"

    getter params : Utils::ParamsHash
    getter headers : HTTP::Headers
    getter url_prefix : URI = URI.parse("http:/")
    getter builder : RackBuilder
    getter ssl : SSLOptions
    getter proxy : ProxyOptions?
    getter parallel_manager : Nil

    def initialize(url : String? = nil, options : ConnectionOptions = ConnectionOptions.new)
      @params = Utils::ParamsHash.new
      @headers = HTTP::Headers.new
      @ssl = options.ssl
      @parallel_manager = nil
      @proxy = nil
      @request_options = options.request

      @builder = options.builder || RackBuilder.new do |b|
        b.adapter(Faraday.default_adapter)
      end

      self.url_prefix = url || options.url || "http:/"

      if (p = options.params)
        @params.update(p)
      end
      if (h = options.headers)
        h.each { |k, v| @headers[k] = v }
      end

      @headers["User-Agent"] ||= USER_AGENT
    end

    def initialize(url : String? = nil, options : ConnectionOptions = ConnectionOptions.new, &block : Connection ->)
      initialize(url, options)
      block.call(self)
    end

    def url_prefix=(url : String)
      @url_prefix = URI.parse(url.empty? ? "http:/" : url)
      uri = @url_prefix
      if (q = uri.query)
        @params.merge_query(q)
        @url_prefix = URI.new(uri.scheme, uri.host, uri.port, uri.path, nil, uri.fragment, uri.user, uri.password)
      end
    end

    def url_prefix=(url : URI)
      @url_prefix = url
    end

    def path_prefix : String
      @url_prefix.path
    end

    def path_prefix=(value : String?)
      path = if value
               value.starts_with?("/") ? value : "/#{value}"
             else
               "/"
             end
      uri = @url_prefix
      @url_prefix = URI.new(uri.scheme, uri.host, uri.port, path, nil, uri.fragment, uri.user, uri.password)
    end

    # HTTP methods that send query params (no body)
    def get(url : String? = nil, params = nil, headers = nil) : Response
      run_request(:get, url, nil, headers) do |req|
        req.params.update(params) if params
      end
    end

    def head(url : String? = nil, params = nil, headers = nil) : Response
      run_request(:head, url, nil, headers) do |req|
        req.params.update(params) if params
      end
    end

    def delete(url : String? = nil, params = nil, headers = nil) : Response
      run_request(:delete, url, nil, headers) do |req|
        req.params.update(params) if params
      end
    end

    def trace(url : String? = nil, params = nil, headers = nil) : Response
      run_request(:trace, url, nil, headers) do |req|
        req.params.update(params) if params
      end
    end

    # HTTP methods that send a body
    def post(url : String? = nil, body : String? = nil, headers = nil) : Response
      run_request(:post, url, body, headers)
    end

    def post(url : String? = nil, body : String? = nil, headers = nil, &block : Request ->) : Response
      run_request(:post, url, body, headers, &block)
    end

    def post(url : String? = nil, body : Hash(K, V) = nil, headers = nil) : Response forall K, V
      run_request(:post, url, JSON.parse(body.to_json), headers)
    end

    def post(url : String? = nil, body : Array(T) = nil, headers = nil) : Response forall T
      run_request(:post, url, JSON.parse(body.to_json), headers)
    end

    def put(url : String? = nil, body : String? = nil, headers = nil) : Response
      run_request(:put, url, body, headers)
    end

    def put(url : String? = nil, body : String? = nil, headers = nil, &block : Request ->) : Response
      run_request(:put, url, body, headers, &block)
    end

    def put(url : String? = nil, body : Hash(K, V) = nil, headers = nil) : Response forall K, V
      run_request(:put, url, JSON.parse(body.to_json), headers)
    end

    def put(url : String? = nil, body : Array(T) = nil, headers = nil) : Response forall T
      run_request(:put, url, JSON.parse(body.to_json), headers)
    end

    def patch(url : String? = nil, body : String? = nil, headers = nil) : Response
      run_request(:patch, url, body, headers)
    end

    def patch(url : String? = nil, body : String? = nil, headers = nil, &block : Request ->) : Response
      run_request(:patch, url, body, headers, &block)
    end

    def patch(url : String? = nil, body : Hash(K, V) = nil, headers = nil) : Response forall K, V
      run_request(:patch, url, JSON.parse(body.to_json), headers)
    end

    def patch(url : String? = nil, body : Array(T) = nil, headers = nil) : Response forall T
      run_request(:patch, url, JSON.parse(body.to_json), headers)
    end

    # Build and run a request.
    def run_request(method : Symbol, url : String?, body : JSON::Any | String | Nil, headers = nil) : Response
      unless METHODS.includes?(method)
        raise ArgumentError.new("unknown http method: #{method}")
      end
      request = build_request(method) do |req|
        req.url(url) if url
        if h = headers
          h.each { |k, v| req.headers[k.to_s] = v.to_s }
        end
        req.body = body
      end
      @builder.build_response(self, request)
    end

    def run_request(method : Symbol, url : String?, body : JSON::Any | String | Nil, headers = nil, &block : Request ->) : Response
      unless METHODS.includes?(method)
        raise ArgumentError.new("unknown http method: #{method}")
      end
      request = build_request(method) do |req|
        req.url(url) if url
        if h = headers
          h.each { |k, v| req.headers[k.to_s] = v.to_s }
        end
        req.body = body
        block.call(req)
      end
      @builder.build_response(self, request)
    end

    def build_request(method : Symbol, &block : Request ->) : Request
      Request.new(method).tap do |req|
        req.params = @params.dup
        req.headers = @headers.dup
        req.options = @request_options.dup
        block.call(req)
      end
    end

    def build_request(method : Symbol) : Request
      build_request(method) { }
    end

    # Build an absolute URL combining the url_prefix with a relative path.
    def build_exclusive_url(path : String = "", params : Utils::ParamsHash? = nil, options : RequestOptions? = nil) : URI
      base = @url_prefix

      uri =
        if path.empty?
          base
        elsif path.starts_with?("http://") || path.starts_with?("https://")
          URI.parse(path)
        elsif path.starts_with?("/")
          URI.new(base.scheme, base.host, base.port, path)
        else
          base_path = base.path
          base_path = base_path.empty? ? "/" : base_path
          base_path = "#{base_path}/" unless base_path.ends_with?("/")
          URI.new(base.scheme, base.host, base.port, "#{base_path}#{path}")
        end

      # Merge connection-level params then request-level params
      query_params = @params.dup
      if (q = uri.query)
        query_params.merge_query(q)
      end
      if params && !params.empty?
        query_params.update(params)
      end

      query = query_params.empty? ? nil : query_params.to_query
      URI.new(uri.scheme, uri.host, uri.port, uri.path, query, nil, uri.user, uri.password)
    end

    # Overload that accepts plain Hash(String, String) (converts to ParamsHash).
    def build_exclusive_url(path : String, params : Hash(String, String), options : RequestOptions? = nil) : URI
      ph = Utils::ParamsHash.new
      params.each { |k, v| ph[k] = v }
      build_exclusive_url(path, ph, options)
    end

    delegate use, to: @builder
    delegate adapter, to: @builder
    delegate request, to: @builder
    delegate response, to: @builder

    def close
      @builder.app.close
    end
  end
end
