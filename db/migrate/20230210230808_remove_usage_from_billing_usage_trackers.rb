class RemoveUsageFromBillingUsageTrackers < ActiveRecord::Migration[7.0]
  def change
    remove_column :billing_usage_trackers, :usage, :jsonb, default: {}
  end
end
