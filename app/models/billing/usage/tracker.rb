class Billing::Usage::Tracker < BulletTrain::Billing::Usage.base_class.constantize
  # e.g. `belongs_to :team`
  belongs_to BulletTrain::Billing::Usage.parent_association

  # TODO: This is only here to satify a test in `limiter_test.rb` that is testing a
  # scenario that we belive isn't actualy a valid use-case. That is, people won't be
  # actually limiting trackers. That test should probably be located in the starter
  # repo so that it has access to other models. Move that test and then remove this scope.
  scope :billable, -> { all }

  has_many :counts, dependent: :destroy do
    def for(action, model)
      order(created_at: :desc).find_by(action: action, name: model.to_s)
    end
  end

  def self.cycles(parent)
    Billing::Usage::ProductCatalog.new(parent).cycles
  end

  def track(action, model, count)
    count_id = counts.find_or_create_by(action: action, name: model.to_s).id
    Billing::Usage::Count.update_counters(count_id, count: count, touch: true)
  end

  def cycle_as_needed
    return nil unless needs_cycling?

    send(BulletTrain::Billing::Usage.parent_association).billing_usage_trackers.create(duration: duration, interval: interval)
  end

  def needs_cycling?
    created_at + duration.send(interval) < Time.zone.now
  end
end
