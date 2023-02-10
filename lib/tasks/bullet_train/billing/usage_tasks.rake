namespace :billing do
  namespace :usage do
    desc "Update the usage count data to the new usage format"
    task update_counts: :environment do
      Billing::Usage.trackers.each do |tracker|
        tracker.find_each do |team|
          team.billing_usage_trackers.current.each do |tracker|
            tracker.usage.map do |model, counts|
              counts.map do |action, count|
                tracker.track(action, model, count)
              end
            end
          end
        end
      end
    end
  end
end
