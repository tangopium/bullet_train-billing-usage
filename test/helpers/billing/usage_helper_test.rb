require "test_helper"

class Billing::UsageHelperTest < ActiveSupport::TestCase
  class DummyClass; end

  class DummyController
    include Billing::UsageHelper
  end

  setup do
    @model = DummyClass

    @limits = [{action: :have, usage: 3, limit: {"count" => 3, "enforcement" => "hard", "upgradable" => true, "product_id" => "basic"}}]
    @limiter = Minitest::Mock.new
    @limiter.expect :broken_hard_limits_for, @limits, [:create, @model], count: Integer

    @dummy = DummyController.new
  end

  test "#broken_hard_limits_message returns a message that you can't anymore of the model if you are trying to add more" do
    message = @dummy.broken_hard_limits_message(@limiter, @model)

    assert_includes message, "You can't add a Membership"
  end

  test "#broken_hard_limits_message returns the broken limits alongside the current limits" do
    message = @dummy.broken_hard_limits_message(@limiter, @model)

    assert_includes message, "because you already have 3 out of 3 Memberships"
  end

  test "#broken_hard_limits_message returns a message that you already have if you are not trying to add more" do
    message = @dummy.broken_hard_limits_message(@limiter, @model, count: 0)

    assert_includes message, "You've used 3 of 3 Memberships"
  end

  test "#broken_hard_limits_message returns the product name that had the broken limits" do
    message = @dummy.broken_hard_limits_message(@limiter, @model)

    assert_includes message, "allowed by your Basic account."
  end

  test "#broken_hard_limits_message returns the broken limits for another action" do
    @limits.first[:action] = :create

    message = @dummy.broken_hard_limits_message(@limiter, @model)

    assert_includes message, "You can't create a Membership because you've already created 3 out of 3 Memberships"
  end

  test "#broken_hard_limits_message returns the interval if that is specified in the config" do
    @limits.first[:action] = :create
    @limits.first[:limit].merge!({"duration" => 1, "interval" => "months"})

    message = @dummy.broken_hard_limits_message(@limiter, @model)

    assert_includes message, "allowed by your Basic account in the current 1 month period."
  end
end
