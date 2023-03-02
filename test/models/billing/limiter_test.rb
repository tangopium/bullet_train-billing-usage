require "test_helper"

class Billing::LimiterTest < ActiveSupport::TestCase
  class TestLimiter
    include Billing::Limiter::Base

    def current_products
      [OpenStruct.new(id: "basic",
        limits: {"blahs" => {"create" => {"count" => 2,
                                          "enforcement" => "hard",
                                          "duration" => 1,
                                          "interval" => "month"}}})]
    end
  end

  describe "with a stubbed product catalog" do
    let(:all_products) { limiter.current_products }
    let(:limiter) { TestLimiter.new(team) }
    let(:team) { FactoryBot.create(:team) }

    describe "#broken_hard_limits_for" do
      it "returns an empty array for no broken hard limits" do
        Billing::Usage::ProductCatalog.stub(:all_products, all_products) do
          assert_empty limiter.broken_hard_limits_for(:create, "Blah")
        end
      end

      it "returns the broken limits if they are broken" do
        tracker = FactoryBot.create(:tracker, team: team, interval: "month", duration: 1)
        FactoryBot.create(:count, tracker: tracker, action: "created", name: "Blah", count: 2)

        Billing::Usage::ProductCatalog.stub(:all_products, all_products) do
          assert_equal limiter.broken_hard_limits_for(:create, "Blah"), [
            {action: :create,
             usage: 2,
             limit: {"count" => 2,
                     "enforcement" => "hard",
                     "duration" => 1,
                     "interval" => "month",
                     "product_id" => "basic"}}
          ]
        end
      end

      it "returns the broken limits if they could be broken by the count" do
        Billing::Usage::ProductCatalog.stub(:all_products, all_products) do
          assert_equal limiter.broken_hard_limits_for(:create, "Blah", count: 3), [
            {action: :create,
             usage: 0,
             limit: {"count" => 2,
                     "enforcement" => "hard",
                     "duration" => 1,
                     "interval" => "month",
                     "product_id" => "basic"}}
          ]
        end
      end
    end

    describe "#exhausted_usage_for" do
      let(:limit) { {"count" => 2, "duration" => 1, "interval" => "month"} }

      it "returns nil if the limit has not been exhausted" do
        Billing::Usage::ProductCatalog.stub(:all_products, all_products) do
          assert_nil limiter.exhausted_usage_for(limit, :create, "Blah")
        end
      end

      it "returns the usage count for the specified exhausted limit" do
        tracker = FactoryBot.create(:tracker, team: team, interval: "month", duration: 1)
        FactoryBot.create(:count, tracker: tracker, action: "created", name: "Blah", count: 3)

        Billing::Usage::ProductCatalog.stub(:all_products, all_products) do
          assert_equal limiter.exhausted_usage_for(limit, :create, "Blah"), 3
        end
      end

      it "returns nil if the count does not exceed the limit" do
        tracker = FactoryBot.create(:tracker, team: team, interval: "month", duration: 1)
        FactoryBot.create(:count, tracker: tracker, action: "created", name: "Blah", count: 2)

        Billing::Usage::ProductCatalog.stub(:all_products, all_products) do
          assert_nil limiter.exhausted_usage_for(limit, :create, "Blah")
        end
      end
    end
  end
end
