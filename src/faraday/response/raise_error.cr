module Faraday
  class Response
    # Middleware that raises exceptions for 4xx/5xx HTTP responses.
    class RaiseError < Faraday::Middleware
      def initialize(@app : Handler, @allowed_statuses : Array(Int32) = [] of Int32)
      end

      def on_complete(env : Env)
        status = env.status || 0
        return if @allowed_statuses.includes?(status)
        case status
        when 400
          raise Faraday::BadRequestError.new(build_message(env), response_for(env))
        when 401
          raise Faraday::UnauthorizedError.new(build_message(env), response_for(env))
        when 403
          raise Faraday::ForbiddenError.new(build_message(env), response_for(env))
        when 404
          raise Faraday::ResourceNotFound.new(build_message(env), response_for(env))
        when 407
          raise Faraday::ProxyAuthError.new(build_message(env), response_for(env))
        when 408
          raise Faraday::RequestTimeoutError.new(build_message(env), response_for(env))
        when 409
          raise Faraday::ConflictError.new(build_message(env), response_for(env))
        when 422
          raise Faraday::UnprocessableContentError.new(build_message(env), response_for(env))
        when 429
          raise Faraday::TooManyRequestsError.new(build_message(env), response_for(env))
        when 400..499
          raise Faraday::ClientError.new(build_message(env), response_for(env))
        when 500..599
          raise Faraday::ServerError.new(build_message(env), response_for(env))
        when 0
          raise Faraday::NilStatusError.new
        end
      end

      private def response_for(env : Env) : Response
        r = Response.new
        r.finish(env)
        r
      end

      private def build_message(env : Env) : String
        "the server responded with status #{env.status}"
      end
    end
  end
end

