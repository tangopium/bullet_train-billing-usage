require "test_helper"

class Billing::UsageTest < ActiveSupport::TestCase
  describe ".trackers" do
    before { Team }

    it "returns all the models that inherit from `HasTrackers`" do
      assert_equal Billing::Usage.trackers, [Team]
    end
  end
end
