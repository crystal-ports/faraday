module Faraday
  # Response wraps a finished HTTP response from the middleware stack.
  class Response
    getter env : Env?

    def initialize
      @env = nil
      @on_complete_callbacks = [] of Env ->
    end

    def initialize(env : Env)
      @env = env
      @on_complete_callbacks = [] of Env ->
    end

    # Convenience constructor used by adapter.
    def initialize(status : Int32, body : String?, headers : HTTP::Headers)
      env = Env.new
      env.status = status
      env.response_body = body
      env.response_headers = headers
      @env = env
      @on_complete_callbacks = [] of Env ->
    end

    def status : Int32?
      @env.try(&.status)
    end

    def reason_phrase : String?
      @env.try(&.reason_phrase)
    end

    def headers : HTTP::Headers
      @env.try(&.response_headers) || HTTP::Headers.new
    end

    def body : String?
      @env.try(&.response_body)
    end

    def url : URI?
      @env.try(&.url)
    end

    def finished? : Bool
      !@env.nil?
    end

    def success? : Bool
      finished? && @env.not_nil!.success?
    end

    def on_complete(&block : Env ->)
      if finished?
        block.call(@env.not_nil!)
      else
        @on_complete_callbacks << block
      end
      self
    end

    def finish(env : Env)
      raise RuntimeError.new("response already finished") if finished?
      @env = env
      @on_complete_callbacks.each { |cb| cb.call(env) }
      self
    end

    def [](key : String) : String
      headers[key]
    end
  end
end
