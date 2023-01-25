require "test_helper"

class Billing::UsageTest < ActiveSupport::TestCase
  class DummyTracker < ApplicationRecord
    include Billing::Usage::HasTrackers
  end

  describe ".trackers" do
    it "returns all the models that inherit from `HasTrackers`" do
      assert_equal Billing::Usage.trackers, [DummyTracker]
    end
  end
end
