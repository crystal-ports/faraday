require "../spec_helper"

Spectator.describe Faraday::Error do
  describe ".new with string message" do
    subject { Faraday::Error.new("oops") }

    it "sets the message" do
      expect(subject.message).to eq("oops")
    end

    it "has no wrapped exception" do
      expect(subject.wrapped_exception).to be_nil
    end

    it "has no response" do
      expect(subject.response).to be_nil
    end

    it "has nil response_status" do
      expect(subject.response_status).to be_nil
    end

    it "has nil response_headers" do
      expect(subject.response_headers).to be_nil
    end

    it "has nil response_body" do
      expect(subject.response_body).to be_nil
    end
  end

  describe ".new with default message" do
    subject { Faraday::Error.new }

    it "can be instantiated without arguments" do
      expect(subject).to be_a(Faraday::Error)
    end

    it "has no wrapped exception" do
      expect(subject.wrapped_exception).to be_nil
    end
  end

  describe ".new with Exception" do
    let(original) { RuntimeError.new("original message") }
    subject { Faraday::Error.new(original) }

    it "wraps the exception" do
      expect(subject.wrapped_exception).to eq(original)
    end

    it "uses the exception message" do
      expect(subject.message).to eq("original message")
    end

    it "has no response" do
      expect(subject.response).to be_nil
    end
  end

  describe "Hash-based constructor" do
    pending "Ruby Faraday::Error.new(hash) is not supported in Crystal" do
      # Ruby: Faraday::Error.new({ status: 400, body: 'error' })
      # Crystal: only String or Exception constructors
    end
  end

  describe "error hierarchy — ClientError subclasses" do
    it "ClientError is a Faraday::Error" do
      expect(Faraday::ClientError.new).to be_a(Faraday::Error)
    end

    it "BadRequestError is a ClientError" do
      expect(Faraday::BadRequestError.new).to be_a(Faraday::ClientError)
    end

    it "UnauthorizedError is a ClientError" do
      expect(Faraday::UnauthorizedError.new).to be_a(Faraday::ClientError)
    end

    it "ForbiddenError is a ClientError" do
      expect(Faraday::ForbiddenError.new).to be_a(Faraday::ClientError)
    end

    it "ResourceNotFound is a ClientError" do
      expect(Faraday::ResourceNotFound.new).to be_a(Faraday::ClientError)
    end

    it "ProxyAuthError is a ClientError" do
      expect(Faraday::ProxyAuthError.new).to be_a(Faraday::ClientError)
    end

    it "RequestTimeoutError is a ClientError" do
      expect(Faraday::RequestTimeoutError.new).to be_a(Faraday::ClientError)
    end

    it "ConflictError is a ClientError" do
      expect(Faraday::ConflictError.new).to be_a(Faraday::ClientError)
    end

    it "UnprocessableContentError is a ClientError" do
      expect(Faraday::UnprocessableContentError.new).to be_a(Faraday::ClientError)
    end

    it "UnprocessableEntityError is an alias for UnprocessableContentError" do
      expect(Faraday::UnprocessableEntityError.new).to be_a(Faraday::UnprocessableContentError)
    end

    it "TooManyRequestsError is a ClientError" do
      expect(Faraday::TooManyRequestsError.new).to be_a(Faraday::ClientError)
    end
  end

  describe "error hierarchy — ServerError subclasses" do
    it "ServerError is a Faraday::Error" do
      expect(Faraday::ServerError.new).to be_a(Faraday::Error)
    end

    it "TimeoutError is a ServerError" do
      expect(Faraday::TimeoutError.new).to be_a(Faraday::ServerError)
    end

    it "NilStatusError is a ServerError" do
      expect(Faraday::NilStatusError.new).to be_a(Faraday::ServerError)
    end
  end

  describe "error hierarchy — standalone errors" do
    it "ConnectionFailed is a Faraday::Error" do
      expect(Faraday::ConnectionFailed.new).to be_a(Faraday::Error)
    end

    it "SSLError is a Faraday::Error" do
      expect(Faraday::SSLError.new).to be_a(Faraday::Error)
    end

    it "ParsingError is a Faraday::Error" do
      expect(Faraday::ParsingError.new).to be_a(Faraday::Error)
    end

    it "InitializationError is a Faraday::Error" do
      expect(Faraday::InitializationError.new).to be_a(Faraday::Error)
    end
  end

  describe "is_a? Exception" do
    it "Faraday::Error is an Exception" do
      expect(Faraday::Error.new("msg")).to be_a(Exception)
    end
  end
end
