FactoryBot.define do
  factory :count, class: "Billing::Usage::Count" do
    name { "ApplicationRecord" }
    action { "created" }
    association :tracker
  end
end
