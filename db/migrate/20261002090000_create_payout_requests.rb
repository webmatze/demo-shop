class CreatePayoutRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :sellers do |t|
      t.string :name, null: false
      t.integer :account_age_days, default: 0, null: false
      t.integer :orders, default: 0, null: false
      t.integer :lifetime_sales, default: 0, null: false
      t.integer :days_since_last_order, default: 0, null: false
      t.integer :iban_changed_hours_ago
      t.string :login_country
      t.timestamps
    end

    create_table :payout_requests do |t|
      t.references :seller, null: false, foreign_key: true
      t.integer :amount, null: false
      t.string :request_country
      t.boolean :via_proxy, default: false, null: false
      # offen -> approved | review | blocked
      t.string :state, default: "open", null: false
      t.float :probability
      t.string :reason
      t.timestamps
    end
    add_index :payout_requests, :state
  end
end
