namespace :billing do
  desc "Create new usage trackers as needed"
  task cycle_usage_trackers: :environment do
    Billing::Usage.trackers.each do |tracker|
      tracker.find_each do |parent|
        parent.billing_usage_trackers.current.each do |billing_usage_tracker|
          billing_usage_tracker.cycle_as_needed
        end
      end
    end
  end
end
