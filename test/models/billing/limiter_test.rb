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

  class TestForHaveLimiter
    include Billing::Limiter::Base

    def current_products
      [OpenStruct.new(id: "basic",
        limits: {"billing_usage_trackers" => {"have" => {"count" => 1,
                                                         "enforcement" => "hard",
                                                         "duration" => 1,
                                                         "interval" => "month"}}})]
    end
  end

  class MultipleProductTestLimiter
    include Billing::Limiter::Base

    def current_products
      [
        OpenStruct.new(id: "basic",
          limits: {"blahs" => {"create" => {"count" => 2,
                                            "enforcement" => "hard",
                                            "duration" => 1,
                                            "interval" => "month"}}}),
        OpenStruct.new(id: "upgrade",
          limits: {"blahs" => {"create" => {"count" => 3,
                                            "enforcement" => "hard",
                                            "duration" => 1,
                                            "interval" => "month"}}})
      ]
    end
  end

  class MultipleProductWithUnlimitedTestLimiter
    include Billing::Limiter::Base

    def current_products
      [
        OpenStruct.new(id: "basic",
          limits: {"blahs" => {"create" => {"count" => 2,
                                            "enforcement" => "hard",
                                            "duration" => 1,
                                            "interval" => "month"}}}),
        OpenStruct.new(id: "upgrade",
          limits: {"blahs" => {"create" => {"count" => nil,
                                            "enforcement" => "hard",
                                            "duration" => 1,
                                            "interval" => "month"}}})
      ]
    end
  end

  describe "with a stubbed product catalog of a single limit" do
    let(:all_products) { limiter.current_products }
    let(:limiter) { TestLimiter.new(team) }
    let(:team) { FactoryBot.create(:team) }

    describe "#broken_hard_limits_for" do
      describe "asking for limits for something that is not limited" do
        it "returns an empty array for no broken hard limits" do
          Billing::Usage::ProductCatalog.stub(:all_products, all_products) do
            assert_empty limiter.broken_hard_limits_for(:create, "SOMETHING WE DO NOT LIMIT")
          end
        end
      end

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

      describe "have" do
        let(:all_products) { limiter.current_products }
        let(:limiter) { TestForHaveLimiter.new(team) }
        let(:team) { FactoryBot.create(:team) }

        describe "can have" do
          it "returns an empty array for no broken hard limits" do
            Billing::Usage::ProductCatalog.stub(:all_products, all_products) do
              assert_empty limiter.broken_hard_limits_for(:have, "Billing::Usage::Tracker")
            end
          end
        end

        describe "cannot have" do
          it "returns the broken limits" do
            FactoryBot.create(:tracker, team: team, interval: "month", duration: 1)

            Billing::Usage::ProductCatalog.stub(:all_products, all_products) do
              assert_equal limiter.broken_hard_limits_for(:have, "Billing::Usage::Tracker"), [
                {action: :have,
                 usage: 1,
                 limit: {"count" => 1,
                         "enforcement" => "hard",
                         "duration" => 1,
                         "interval" => "month",
                         "product_id" => "basic"}}
              ]
            end
          end
        end
      end

      describe "multiple products, that limit the same underlying object" do
        let(:all_products) { limiter.current_products }
        let(:limiter) { MultipleProductTestLimiter.new(team) }
        let(:team) { FactoryBot.create(:team) }

        describe "when we are surpassing the lower limit" do
          it "returns an empty array for no broken hard limits" do
            tracker = FactoryBot.create(:tracker, team: team, interval: "month", duration: 1)
            FactoryBot.create(:count, tracker: tracker, action: "created", name: "Blah", count: 2)

            Billing::Usage::ProductCatalog.stub(:all_products, all_products) do
              assert_empty limiter.broken_hard_limits_for(:create, "Blah")
            end
          end
        end

        describe "when we are surpassing the higher limit" do
          it "returns the broken limit" do
            tracker = FactoryBot.create(:tracker, team: team, interval: "month", duration: 1)
            FactoryBot.create(:count, tracker: tracker, action: "created", name: "Blah", count: 3)

            Billing::Usage::ProductCatalog.stub(:all_products, all_products) do
              assert_equal limiter.broken_hard_limits_for(:create, "Blah"), [
                {action: :create,
                 usage: 3,
                 limit: {"count" => 3,
                         "enforcement" => "hard",
                         "duration" => 1,
                         "interval" => "month",
                         "product_id" => "upgrade"}}
              ]
            end
          end
        end

        describe "one limit has a nil count (unlimited)" do
          let(:all_products) { limiter.current_products }
          let(:limiter) { MultipleProductWithUnlimitedTestLimiter.new(team) }
          let(:team) { FactoryBot.create(:team) }

          describe "when we are surpassing the lower limit by a lot" do
            it "returns an empty array for no broken hard limits" do
              tracker = FactoryBot.create(:tracker, team: team, interval: "month", duration: 1)
              FactoryBot.create(:count, tracker: tracker, action: "created", name: "Blah", count: 5)

              Billing::Usage::ProductCatalog.stub(:all_products, all_products) do
                assert_empty limiter.broken_hard_limits_for(:create, "Blah")
              end
            end
          end
        end
      end
    end

    describe "#exhausted_usage_for" do
      let(:limit) { {"count" => 2, "duration" => 1, "interval" => "month"} }
      let(:unlimited_limit) { {"count" => nil, "duration" => 1, "interval" => "month"} }

      it "returns nil if the limit has not been exhausted" do
        Billing::Usage::ProductCatalog.stub(:all_products, all_products) do
          assert_nil limiter.exhausted_usage_for(limit, :create, "Blah")
        end
      end

      it "returns nil if the limit can not be exhausted" do
        Billing::Usage::ProductCatalog.stub(:all_products, all_products) do
          assert_nil limiter.exhausted_usage_for(unlimited_limit, :create, "Blah")
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
