module Billing::UsageSupport
  extend ActiveSupport::Concern

  def track_billing_usage(action, model: nil, count: 1)
    model ||= self.class

    send(BulletTrain::Billing::Usage.parent_association).current_billing_usage_trackers.each do |tracker|
      tracker.track(action, model, count)
    end
  end
end
