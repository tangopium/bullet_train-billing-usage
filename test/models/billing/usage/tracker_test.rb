require "test_helper"

class Billing::Usage::TrackerTest < ActiveSupport::TestCase
  describe "#track" do
    let(:tracker) { FactoryBot.create(:tracker) }

    it "sets the count for a new specific model and action" do
      assert_equal tracker.counts.length, 0

      tracker.track(:created, ApplicationRecord, 1)

      assert_equal tracker.counts.reload.length, 1
      assert_equal tracker.counts.last.name, "ApplicationRecord"
      assert_equal tracker.counts.last.action, "created"
      assert_equal tracker.counts.last.count, 1
    end

    it "updates the count for an existing specific model and action" do
      tracker.track(:created, ApplicationRecord, 1)
      tracker.track(:created, ApplicationRecord, 3)

      assert_equal tracker.counts.reload.length, 1
      assert_equal tracker.counts.last.name, "ApplicationRecord"
      assert_equal tracker.counts.last.action, "created"
      assert_equal tracker.counts.last.count, 4
    end

    it "creates a new count for a new model" do
      FactoryBot.create(:count, name: "Blah", tracker: tracker)

      tracker.track(:created, ApplicationRecord, 1)

      assert_equal tracker.counts.reload.length, 2
      assert_equal tracker.counts.last.name, "ApplicationRecord"
      assert_equal tracker.counts.last.action, "created"
      assert_equal tracker.counts.last.count, 1
    end
  end
end
