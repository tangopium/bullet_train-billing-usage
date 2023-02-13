class CreateBillingUsageCounts < ActiveRecord::Migration[7.0]
  def change
    create_table :billing_usage_counts do |t|
      t.references :tracker, null: false, foreign_key: { to_table: :billing_usage_trackers }
      t.string :name, null: false
      t.string :action, null: false
      t.integer :count, null: false, default: 0

      t.timestamps
    end

    add_index :billing_usage_counts, [:action, :name, :tracker_id], unique: true
  end
end
