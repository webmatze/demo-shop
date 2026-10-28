class CreatePayoutExports < ActiveRecord::Migration[8.1]
  def change
    create_table :payout_exports do |t|
      t.references :seller, null: false, foreign_key: true
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.text :csv
      t.timestamps
    end
  end
end
