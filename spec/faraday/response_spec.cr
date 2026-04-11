require "../spec_helper"

Spectator.describe Faraday::Response do
  let(env) {
    e = Faraday::Env.new
    e.method = :get
    e.url = URI.parse("https://lostisland.github.io/faraday")
    e.status = 404
    e.response_body = "yikes"
    headers = HTTP::Headers{"Content-Type" => "text/plain"}
    e.response_headers = headers
    e
  }

  subject { Faraday::Response.new(env) }

  it "is finished" do
    expect(subject.finished?).to be_true
  end

  it "is not successful for 404" do
    expect(subject.success?).to be_false
  end

  it "returns the status" do
    expect(subject.status).to eq(404)
  end

  it "returns the body" do
    expect(subject.body).to eq("yikes")
  end

  it "returns the url" do
    expect(subject.url).not_to be_nil
    expect(subject.url.not_nil!.host).to eq("lostisland.github.io")
  end

  it "returns headers by name" do
    expect(subject.headers["Content-Type"]).to eq("text/plain")
  end

  it "supports case-insensitive header access via []" do
    expect(subject["content-type"]).to eq("text/plain")
  end

  describe "#finish" do
    it "raises RuntimeError when already finished" do
      expect { subject.finish(env) }.to raise_error(RuntimeError)
    end
  end

  describe "#on_complete" do
    subject { Faraday::Response.new }

    it "calls block when finish is called" do
      called = false
      subject.on_complete { |_e| called = true }
      subject.finish(env)
      expect(called).to be_true
    end

    it "can mutate body in the on_complete block" do
      subject.on_complete { |e| e.response_body = e.response_body.to_s.upcase }
      subject.finish(env)
      expect(subject.body).to eq("YIKES")
    end

    it "can access response body in the block via subject" do
      result = nil
      subject.on_complete { |_e| result = subject.body }
      subject.finish(env)
      expect(result).not_to be_nil
    end
  end

  describe "#env" do
    it "returns the Env" do
      expect(subject.env).not_to be_nil
      expect(subject.env).to be_a(Faraday::Env)
    end
  end

  describe "unfinished response" do
    subject { Faraday::Response.new }

    it "is not finished" do
      expect(subject.finished?).to be_false
    end

    it "has nil status" do
      expect(subject.status).to be_nil
    end

    it "has nil body" do
      expect(subject.body).to be_nil
    end

    it "has empty headers" do
      expect(subject.headers).not_to be_nil
    end
  end

  describe "marshal serialization" do
    pending "Crystal does not use Marshal — serialization not applicable"
  end

  describe "#apply_request" do
    pending "apply_request is a Ruby-specific method, not ported to Crystal"
  end

  describe "#to_hash" do
    pending "to_hash is a Ruby-specific method, not ported to Crystal"
  end
end
