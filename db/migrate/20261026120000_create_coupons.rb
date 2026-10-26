class CreateCoupons < ActiveRecord::Migration[8.1]
  def change
    create_table :coupons do |t|
      t.string :code, null: false
      t.integer :percent_off, null: false
      t.references :order, foreign_key: true, index: { unique: true }
      t.timestamps
    end
    add_index :coupons, :code, unique: true
  end
end