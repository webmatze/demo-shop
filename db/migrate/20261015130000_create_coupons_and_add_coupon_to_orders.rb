class CreateCouponsAndAddCouponToOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :coupons do |t|
      t.string :code, null: false
      t.integer :percent_off, null: false

      t.timestamps
    end

    add_index :coupons, "lower(code)", unique: true, name: "index_coupons_on_lower_code"
    add_reference :orders, :coupon, foreign_key: true, index: { unique: true }
  end
end
