require "../../spec_helper"

# Faraday::Options in Ruby is a metaprogramming DSL (subclass of Struct) with
# class-level .new, .from, .merge, #update, #to_h, #each, etc.
# Crystal does not have an equivalent DSL; concrete options classes are used instead.
# These tests cover Crystal's concrete options classes.

Spectator.describe Faraday::RequestOptions do
  subject { Faraday::RequestOptions.new }

  it "has nil timeout by default" do
    expect(subject.timeout).to be_nil
  end

  it "has nil open_timeout by default" do
    expect(subject.open_timeout).to be_nil
  end

  it "has nil read_timeout by default" do
    expect(subject.read_timeout).to be_nil
  end

  it "has nil write_timeout by default" do
    expect(subject.write_timeout).to be_nil
  end

  it "allows setting timeout" do
    subject.timeout = 30
    expect(subject.timeout).to eq(30)
  end

  it "allows setting open_timeout" do
    subject.open_timeout = 5
    expect(subject.open_timeout).to eq(5)
  end

  it "allows setting read_timeout" do
    subject.read_timeout = 10
    expect(subject.read_timeout).to eq(10)
  end

  it "allows setting write_timeout" do
    subject.write_timeout = 15
    expect(subject.write_timeout).to eq(15)
  end

  pending "Ruby Faraday::Options DSL (new with keyword args, from, merge, update, to_h) is not ported to Crystal"
  pending "Faraday::RequestOptions.new(timeout: 5) is Ruby-specific keyword argument syntax"
end

Spectator.describe Faraday::SSLOptions do
  subject { Faraday::SSLOptions.new }

  it "can be instantiated" do
    expect(subject).not_to be_nil
  end

  it "responds to verify" do
    expect(subject).to respond_to(:verify)
  end

  it "responds to ca_file" do
    expect(subject).to respond_to(:ca_file)
  end

  pending "Full SSLOptions tests depend on Crystal implementation details"
end

Spectator.describe Faraday::ConnectionOptions do
  subject { Faraday::ConnectionOptions.new }

  it "can be instantiated" do
    expect(subject).not_to be_nil
  end

  it "has request options" do
    expect(subject.request).to be_a(Faraday::RequestOptions)
  end

  it "has ssl options" do
    expect(subject.ssl).to be_a(Faraday::SSLOptions)
  end

  pending "ConnectionOptions.new(url: ...) with hash options is Ruby-specific"
end
