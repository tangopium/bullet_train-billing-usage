class CreateBillingUsageTrackers < ActiveRecord::Migration[7.0]
  def change
    create_table :billing_usage_trackers do |t|
      t.references :team, null: false, foreign_key: true
      t.integer :duration, null: false
      t.string :interval, null: false
      t.jsonb :usage, default: {}

      t.timestamps
    end
  end
end
