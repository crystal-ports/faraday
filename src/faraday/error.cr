module Faraday
  # Base error class for all Faraday errors.
  class Error < Exception
    getter response : Response?
    getter wrapped_exception : Exception?

    def initialize(message : String = "", @response : Response? = nil)
      @wrapped_exception = nil
      super(message)
    end

    def initialize(exc : Exception, @response : Response? = nil)
      @wrapped_exception = exc
      super(exc.message || "")
    end

    def response_status : Int32?
      @response.try(&.status)
    end

    def response_headers : HTTP::Headers?
      @response.try(&.headers)
    end

    def response_body : String?
      @response.try(&.body)
    end
  end

  # Faraday client error class. Represents 4xx status responses.
  class ClientError < Error; end

  # Raised by Faraday::Response::RaiseError in case of a 400 response.
  class BadRequestError < ClientError; end

  # Raised by Faraday::Response::RaiseError in case of a 401 response.
  class UnauthorizedError < ClientError; end

  # Raised by Faraday::Response::RaiseError in case of a 403 response.
  class ForbiddenError < ClientError; end

  # Raised by Faraday::Response::RaiseError in case of a 404 response.
  class ResourceNotFound < ClientError; end

  # Raised by Faraday::Response::RaiseError in case of a 407 response.
  class ProxyAuthError < ClientError; end

  # Raised by Faraday::Response::RaiseError in case of a 408 response.
  class RequestTimeoutError < ClientError; end

  # Raised by Faraday::Response::RaiseError in case of a 409 response.
  class ConflictError < ClientError; end

  # Raised by Faraday::Response::RaiseError in case of a 422 response.
  class UnprocessableContentError < ClientError; end

  UnprocessableEntityError = UnprocessableContentError

  # Raised by Faraday::Response::RaiseError in case of a 429 response.
  class TooManyRequestsError < ClientError; end

  # Faraday server error class. Represents 5xx status responses.
  class ServerError < Error; end

  # A unified client error for timeouts.
  class TimeoutError < ServerError
    def initialize(message = "timeout", response : Response? = nil)
      super(message, response)
    end
  end

  # Raised by Faraday::Response::RaiseError in case of a nil status in response.
  class NilStatusError < ServerError
    def initialize(message = "http status could not be derived from the server response", response : Response? = nil)
      super(message, response)
    end
  end

  # A unified error for failed connections.
  class ConnectionFailed < Error; end

  # A unified client error for SSL errors.
  class SSLError < Error; end

  # Raised by middlewares that parse the response, like the JSON response middleware.
  class ParsingError < Error; end

  # Raised by Faraday::Middleware and subclasses when invalid default_options are used.
  class InitializationError < Error; end
end
