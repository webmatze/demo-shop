class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.decimal :total, precision: 8, scale: 2, null: false
      t.timestamps
    end
  end
end
