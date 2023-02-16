class MigrateTrackerUsage < ActiveRecord::Migration[7.0]
  def up
    trackers do |tracker|
      (tracker&.usage || {}).map do |model, counts|
        counts.map do |action, count|
          tracker.counts.upsert({action: action,
                                 name: model.to_s,
                                 tracker_id: tracker,
                                 count: count},
                                unique_by: [:action, :name, :tracker_id])
        end
      end
    end
  end

  def down
    trackers do |tracker|
      tracker.counts.order(created_at: :desc).each do |count|
        count.tracker.usage ||= {}
        count.tracker.usage[count.name] ||= {}
        count.tracker.usage[count.name][count.action] = count.count
        count.tracker.save
      end
      tracker.counts.destroy_all
    end
  end

  private

  def trackers
    Billing::Usage.trackers.each do |tracker|
      tracker.find_each do |has_trackers|
        Billing::Usage::Tracker.cycles(has_trackers).map do |cycle|
          duration, interval = cycle

          has_trackers
            .billing_usage_trackers
            .order(created_at: :desc)
            .includes(:counts)
            .find_by(duration: duration, interval: interval)
        end.each do |tracker|
          yield tracker
        end
      end
    end
  end
end
