require "test_helper"

class Billing::UsageHelperTest < ActiveSupport::TestCase
  class DummyClass; end

  class DummyController
    include Billing::UsageHelper
  end

  describe "#broken_hard_limits_message" do
    let(:controller) { DummyController.new }
    let(:limits) { [{action: :have, usage: 3, limit: {"count" => 3, "enforcement" => "hard", "upgradable" => true, "product_id" => "basic"}}] }
    let(:limiter) { Minitest::Mock.new }
    let(:model) { DummyClass }

    before { limiter.expect :broken_hard_limits_for, limits, [:create, model], count: Integer }

    it "returns a message that you can't create anymore of the model if you are trying to add more" do
      message = controller.broken_hard_limits_message(limiter, model)

      assert_includes message, "You can't add a Membership"
    end

    it "returns the broken limits alongside the current limits" do
      message = controller.broken_hard_limits_message(limiter, model)

      assert_includes message, "because you already have 3 out of 3 Memberships"
    end

    it "returns a message that you already have if you are not trying to add more" do
      message = controller.broken_hard_limits_message(limiter, model, count: 0)

      assert_includes message, "You've used 3 of 3 Memberships"
    end

    it "returns the product name that had the broken limits" do
      message = controller.broken_hard_limits_message(limiter, model)

      assert_includes message, "allowed by your Basic account."
    end

    it "returns the broken limits for another action" do
      limits.first[:action] = :create

      message = controller.broken_hard_limits_message(limiter, model)

      assert_includes message, "You can't create a Membership because you've already created 3 out of 3 Memberships"
    end

    it "returns the interval if that is specified in the config" do
      limits.first[:action] = :create
      limits.first[:limit].merge!({"duration" => 1, "interval" => "months"})

      message = controller.broken_hard_limits_message(limiter, model)

      assert_includes message, "allowed by your Basic account in the current 1 month period."
    end
  end

  describe "#broken_soft_limits_message" do
    let(:controller) { DummyController.new }
    let(:limits) { [{action: :have, usage: 3, limit: {"count" => 3, "enforcement" => "soft", "product_id" => "basic"}}] }
    let(:limiter) { Minitest::Mock.new }
    let(:model) { DummyClass }

    before { limiter.expect :broken_soft_limits_for, limits, [:create, model], count: Integer }

    it "returns a message of what you already have" do
      message = controller.broken_soft_limits_message(limiter, model, count: 1)

      assert_includes message, "You've used 3 out of 3 Memberships"
    end

    it "returns the product name that had the broken limits" do
      message = controller.broken_soft_limits_message(limiter, model)

      assert_includes message, "allowed by your Basic account."
    end

    it "returns the broken limits for another action" do
      limits.first[:action] = :create

      message = controller.broken_soft_limits_message(limiter, model, count: 1)

      assert_includes message, "You've created 3 out of 3 Memberships"
    end

    it "returns the interval if that is specified in the config" do
      limits.first[:action] = :create
      limits.first[:limit].merge!({"duration" => 1, "interval" => "months"})

      message = controller.broken_soft_limits_message(limiter, model)

      assert_includes message, "allowed by your Basic account in the current 1 month period."
    end
  end
end
