module Faraday
  # Env is the request/response environment passed through the middleware stack.
  class Env
    CONTENT_LENGTH        = "Content-Length"
    STATUSES_WITHOUT_BODY = Set{204, 304}
    SUCCESSFUL_STATUSES   = 200..299
    METHODS_WITH_BODIES   = Set{:post, :put, :patch}

    property method : Symbol
    property request_body : JSON::Any | String | Nil
    property url : URI?
    property request : RequestOptions
    property request_headers : HTTP::Headers
    property ssl : SSLOptions
    property parallel_manager : Nil
    property params : Utils::ParamsHash
    property response : Response?
    property response_headers : HTTP::Headers?
    property status : Int32?
    property reason_phrase : String?
    property response_body : String?
    property custom_members : Hash(Symbol, String)

    def initialize(
      @method : Symbol = :get,
      @request_body : JSON::Any | String | Nil = nil,
      @url : URI? = nil,
      @request : RequestOptions = RequestOptions.new,
      @request_headers : HTTP::Headers = HTTP::Headers.new,
      @ssl : SSLOptions = SSLOptions.new,
      @parallel_manager = nil,
      @params : Utils::ParamsHash = Utils::ParamsHash.new
    )
      @custom_members = {} of Symbol => String
    end

    def body : JSON::Any | String | Nil
      @status ? @response_body : @request_body
    end

    def body=(value : JSON::Any | String | Nil)
      if @status
        @response_body = value.is_a?(JSON::Any) ? value.to_json : value
      else
        @request_body = value
      end
    end

    def success? : Bool
      s = @status
      s ? SUCCESSFUL_STATUSES.includes?(s) : false
    end

    def needs_body? : Bool
      !body && METHODS_WITH_BODIES.includes?(@method)
    end

    def clear_body
      @request_headers[CONTENT_LENGTH] = "0"
      @request_body = ""
    end

    def parse_body? : Bool
      s = @status
      s ? !STATUSES_WITHOUT_BODY.includes?(s) : true
    end

    def parallel? : Bool
      false
    end

    def stream_response? : Bool
      @request.stream_response?
    end
  end
end
