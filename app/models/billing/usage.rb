module Billing::Usage
  def self.table_name_prefix
    "billing_usage_"
  end

  def self.trackers
    BulletTrain::Billing::Usage.base_class.constantize.descendants.select do |klass|
      klass if klass.include?(Billing::Usage::HasTrackers)
    end.compact
  end
end
