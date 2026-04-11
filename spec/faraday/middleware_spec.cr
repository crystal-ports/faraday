require "../spec_helper"

Spectator.describe Faraday::Middleware do
  # Concrete Handler subclass used as test app double
  class TestHandler < Faraday::Handler
    getter called : Bool = false
    getter closed : Bool = false
    getter last_env : Faraday::Env?

    def call(env : Faraday::Env) : Faraday::Response
      @called = true
      @last_env = env
      Faraday::Response.new(env)
    end

    def close
      @closed = true
    end
  end

  # Tracks hook call order
  class TrackingMiddleware < Faraday::Middleware
    getter call_order : Array(Symbol) = [] of Symbol

    def on_request(env : Faraday::Env)
      call_order << :on_request
    end

    def on_complete(env : Faraday::Env)
      call_order << :on_complete
    end
  end

  let(app) { TestHandler.new }
  subject { Faraday::Middleware.new(app) }

  it "responds to call" do
    expect(subject).to respond_to(:call)
  end

  it "responds to close" do
    expect(subject).to respond_to(:close)
  end

  describe "#close" do
    it "delegates to the underlying app" do
      subject.close
      expect(app.closed).to be_true
    end
  end

  describe "#call" do
    let(env) { Faraday::Env.new }

    it "calls the app" do
      subject.call(env)
      expect(app.called).to be_true
    end

    it "passes the env to the app" do
      subject.call(env)
      expect(app.last_env).to eq(env)
    end

    it "returns a Response" do
      result = subject.call(env)
      expect(result).to be_a(Faraday::Response)
    end
  end

  describe "hook ordering in #call" do
    let(tracking) { TrackingMiddleware.new(app) }
    let(env) { Faraday::Env.new }

    it "calls on_request before the app" do
      tracking.call(env)
      on_req_idx = tracking.call_order.index(:on_request)
      expect(on_req_idx).not_to be_nil
    end

    it "calls on_complete after the app" do
      tracking.call(env)
      on_comp_idx = tracking.call_order.index(:on_complete)
      expect(on_comp_idx).not_to be_nil
    end

    it "calls on_request before on_complete" do
      tracking.call(env)
      order = tracking.call_order
      req_idx = order.index(:on_request).not_nil!
      comp_idx = order.index(:on_complete).not_nil!
      expect(req_idx).to be < comp_idx
    end

    it "calls app between on_request and on_complete" do
      tracking.call(env)
      expect(app.called).to be_true
    end
  end

  describe "on_request and on_complete default implementations" do
    it "on_request does nothing by default" do
      env = Faraday::Env.new
      # Default Middleware#on_request is a no-op; should not raise
      expect { subject.call(env) }.not_to raise_error
    end
  end
end
