require "../../spec_helper"

Spectator.describe Faraday::Response::RaiseError do
  let(stubs) {
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/ok")                  { {200, {} of String => String, "success"} }
      stub.get("/bad-request")         { {400, {"X-Reason" => "because"}, "keep looking"} }
      stub.get("/unauthorized")        { {401, {} of String => String, ""} }
      stub.get("/forbidden")           { {403, {} of String => String, ""} }
      stub.get("/not-found")           { {404, {} of String => String, ""} }
      stub.get("/conflict")            { {409, {"X-Reason" => "because"}, "keep looking"} }
      stub.get("/unprocessable")       { {422, {"X-Reason" => "because"}, "keep looking"} }
      stub.get("/too-many-requests")   { {429, {"X-Reason" => "because"}, "keep looking"} }
      stub.get("/server-error")        { {500, {"X-Error" => "bailout"}, "fail"} }
      stub.get("/4xx")                 { {499, {"X-Reason" => "because"}, "keep looking"} }
    end
  }

  let(conn) {
    Faraday::Connection.new("http://example.com") do |b|
      b.response :raise_error
      b.adapter :test, stubs
    end
  }

  it "does not raise for 200 OK" do
    expect { conn.get("/ok") }.not_to raise_error
  end

  it "raises BadRequestError for 400" do
    expect { conn.get("/bad-request") }.to raise_error(Faraday::BadRequestError)
  end

  it "raises UnauthorizedError for 401" do
    expect { conn.get("/unauthorized") }.to raise_error(Faraday::UnauthorizedError)
  end

  it "raises ForbiddenError for 403" do
    expect { conn.get("/forbidden") }.to raise_error(Faraday::ForbiddenError)
  end

  it "raises ResourceNotFound for 404" do
    expect { conn.get("/not-found") }.to raise_error(Faraday::ResourceNotFound)
  end

  it "raises ConflictError for 409" do
    expect { conn.get("/conflict") }.to raise_error(Faraday::ConflictError)
  end

  it "raises UnprocessableContentError for 422" do
    expect { conn.get("/unprocessable") }.to raise_error(Faraday::UnprocessableContentError)
  end

  it "also raises as UnprocessableEntityError alias for 422" do
    expect { conn.get("/unprocessable") }.to raise_error(Faraday::UnprocessableEntityError)
  end

  it "raises TooManyRequestsError for 429" do
    expect { conn.get("/too-many-requests") }.to raise_error(Faraday::TooManyRequestsError)
  end

  it "raises ServerError for 500" do
    expect { conn.get("/server-error") }.to raise_error(Faraday::ServerError)
  end

  it "raises ClientError for other 4xx" do
    expect { conn.get("/4xx") }.to raise_error(Faraday::ClientError)
  end

  it "includes status in the error message for 400" do
    begin
      conn.get("/bad-request")
    rescue ex : Faraday::BadRequestError
      expect(ex.message).to contain("400")
    end
  end

  it "includes status in the error message for 404" do
    begin
      conn.get("/not-found")
    rescue ex : Faraday::ResourceNotFound
      expect(ex.message).to contain("404")
    end
  end

  it "exposes response_status on the error" do
    begin
      conn.get("/bad-request")
    rescue ex : Faraday::BadRequestError
      expect(ex.response_status).to eq(400)
    end
  end

  it "exposes response_body on the error" do
    begin
      conn.get("/bad-request")
    rescue ex : Faraday::BadRequestError
      expect(ex.response_body).to eq("keep looking")
    end
  end

  it "exposes response_headers on the error" do
    begin
      conn.get("/bad-request")
    rescue ex : Faraday::BadRequestError
      expect(ex.response_headers).not_to be_nil
      expect(ex.response_headers.not_nil!["X-Reason"]).to eq("because")
    end
  end

  describe "NilStatusError" do
    pending "raising NilStatusError for nil status depends on adapter returning nil status" do
      # Crystal adapters may not support nil status natively
    end
  end

  describe "allowed_statuses option" do
    let(allowed_stubs) {
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get("/bad") { {400, {} of String => String, ""} }
        stub.get("/not-found") { {404, {} of String => String, ""} }
      end
    }

    let(conn_with_allowed) {
      Faraday::Connection.new("http://example.com") do |b|
        b.response :raise_error, allowed_statuses: [404]
        b.adapter :test, allowed_stubs
      end
    }

    it "still raises for non-allowed status codes" do
      expect { conn_with_allowed.get("/bad") }.to raise_error(Faraday::BadRequestError)
    end

    it "does not raise for explicitly allowed status codes" do
      expect { conn_with_allowed.get("/not-found") }.not_to raise_error
    end
  end

  describe "request info in exception" do
    pending "request info in exception depends on include_request option implementation" do
    end
  end
end
