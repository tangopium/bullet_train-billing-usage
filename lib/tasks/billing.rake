namespace :billing do
  desc "Create new usage trackers as needed"
  task cycle_usage_trackers: :environment do
    Team.find_each do |team|
      team.billing_usage_trackers.current.each do |tracker|
        tracker.cycle_as_needed
      end
    end
  end
end
