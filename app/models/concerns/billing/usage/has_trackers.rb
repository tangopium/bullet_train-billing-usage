module Billing::Usage::HasTrackers
  extend ActiveSupport::Concern

  included do
    has_many :billing_usage_trackers, class_name: "Billing::Usage::Tracker", dependent: :destroy do
      def current
        Billing::Usage::Tracker.cycles.map do |cycle|
          duration, interval = cycle

          # This will grab the most recent tracker for this usage cycle.
          # If it doesn't exist, it will be created. This can happen if developers introduce new usage cycles to track by.
          order(created_at: :desc).find_or_create_by(duration: duration, interval: interval)
        end
      end
    end
  end
end
