require "../../spec_helper"

# Faraday::Request::Instrumentation is a Ruby-on-Rails/ActiveSupport instrumentation
# middleware that publishes events via ActiveSupport::Notifications.
# Crystal does not have an ActiveSupport equivalent.
# These tests are marked pending as this middleware is unlikely to be ported.

Spectator.describe Faraday::Request::Instrumentation do
  pending "Instrumentation middleware depends on ActiveSupport::Notifications which is Ruby/Rails-specific" do
  end

  describe "middleware setup" do
    pending "b.request :instrumentation is available only if Instrumentation is implemented in Crystal" do
    end
  end

  describe "event publishing" do
    pending "ActiveSupport::Notifications.subscribe is Ruby-only; Crystal has no equivalent" do
    end
  end

  describe "custom event name" do
    pending "instrumentation with custom event name: b.request :instrumentation, name: 'request.faraday'" do
    end
  end
end
