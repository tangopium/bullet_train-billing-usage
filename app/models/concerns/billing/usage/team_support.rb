module Billing::Usage::TeamSupport
  extend ActiveSupport::Concern

  included do
    has_many :billing_usage_trackers, class_name: "Billing::Usage::Tracker", dependent: :destroy
  end

  # TODO Would be great to figure out how to do this as a scope on `billing_usage_trackers`.
  def current_billing_usage_trackers
    Billing::Usage::Tracker.cycles.map do |cycle|
      duration, interval = cycle

      # This will grab the most recent tracker for this usage cycle.
      # If it doesn't exist, it will be created. This can happen if developers introduce new usage cycles to track by.
      billing_usage_trackers.order(created_at: :desc).find_or_create_by(duration: duration, interval: interval)
    end
  end
end
