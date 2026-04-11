require "../spec_helper"

Spectator.describe Faraday::RackBuilder do
  def build_rack_builder(&block : Faraday::RackBuilder ->)
    Faraday::RackBuilder.new(&block)
  end

  subject { build_rack_builder { |_b| } }

  describe "#handlers" do
    it "starts empty" do
      expect(subject.handlers).to be_empty
    end

    it "returns an Array" do
      expect(subject.handlers).to be_a(Array(Faraday::RackBuilder::HandlerSpec))
    end
  end

  describe "#response" do
    it "adds a handler via :raise_error key" do
      subject.response :raise_error
      expect(subject.handlers.size).to eq(1)
    end
  end

  describe "#request" do
    it "adds a handler via :url_encoded key" do
      subject.request :url_encoded
      expect(subject.handlers.size).to eq(1)
    end
  end

  describe "#adapter" do
    it "sets the adapter spec" do
      subject.adapter :test
      expect(subject.adapter_spec).not_to be_nil
    end

    it "sets :net_http adapter" do
      subject.adapter :net_http
      expect(subject.adapter_spec).not_to be_nil
    end
  end

  describe "#lock!" do
    before_each { subject.adapter :test }

    it "locks the builder" do
      subject.lock!
      expect(subject.locked?).to be_true
    end

    it "raises StackLocked when adding middleware after lock" do
      subject.lock!
      expect { subject.response :raise_error }.to raise_error(Faraday::RackBuilder::StackLocked)
    end
  end

  describe "#locked?" do
    it "is false by default" do
      expect(subject.locked?).to be_false
    end

    it "is true after lock!" do
      subject.adapter :test
      subject.lock!
      expect(subject.locked?).to be_true
    end
  end

  describe "#app" do
    before_each { subject.adapter :test }

    it "returns a Handler" do
      app = subject.app
      expect(app).to be_a(Faraday::Handler)
    end

    it "locks the builder" do
      subject.app
      expect(subject.locked?).to be_true
    end
  end

  describe "#to_app" do
    before_each { subject.adapter :test }

    it "returns a Handler" do
      expect(subject.to_app).to be_a(Faraday::Handler)
    end
  end

  describe "multiple middleware" do
    it "stacks middleware in order" do
      subject.request :url_encoded
      subject.response :raise_error
      expect(subject.handlers.size).to eq(2)
    end
  end

  describe "insert_before / insert_after / swap / delete" do
    pending "insert_before is not implemented in Crystal RackBuilder"
    pending "insert_after is not implemented in Crystal RackBuilder"
    pending "swap is not implemented in Crystal RackBuilder"
    pending "delete is not implemented in Crystal RackBuilder"
  end
end
