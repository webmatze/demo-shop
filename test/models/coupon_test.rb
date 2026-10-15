require "test_helper"

class CouponTest < ActiveSupport::TestCase
  setup do
    @coupon = Coupon.create!(code: "WELCOME10", percent_off: 10)
  end

  def new_order(quantity: 2)
    Order.create!(product: products(:one), quantity: quantity) # 12.50 each
  end

  test "applying a code reduces the total by percent_off" do
    order = new_order
    assert order.apply_coupon("WELCOME10")
    assert_equal BigDecimal("22.50"), order.reload.total
    assert_equal @coupon, order.coupon
  end

  test "codes are case-insensitive" do
    order = new_order
    assert order.apply_coupon("welcome10")
    assert_equal BigDecimal("22.50"), order.reload.total
  end

  test "the same order cannot redeem the code twice" do
    order = new_order
    assert order.apply_coupon("WELCOME10")
    assert_not order.apply_coupon("WELCOME10")
    assert_not_empty order.errors[:coupon]
    assert_equal BigDecimal("22.50"), order.reload.total
  end

  test "a code works once across all orders" do
    assert new_order.apply_coupon("WELCOME10")

    second = new_order
    assert_not second.apply_coupon("WELCOME10")
    assert_includes second.errors[:coupon], "has already been redeemed"
    assert_equal BigDecimal("25.00"), second.reload.total
    assert_nil second.coupon
  end

  test "an unknown code fails" do
    order = new_order
    assert_not order.apply_coupon("NOPE")
    assert_includes order.errors[:coupon], "is not valid"
    assert_equal BigDecimal("25.00"), order.reload.total
  end

  test "an order has at most one coupon" do
    Coupon.create!(code: "SPRING20", percent_off: 20)
    order = new_order
    assert order.apply_coupon("WELCOME10")
    assert_not order.apply_coupon("SPRING20")
    assert_not_empty order.errors[:coupon]
    assert_equal @coupon, order.reload.coupon
    assert_equal BigDecimal("22.50"), order.total
  end

  test "the discount survives a later save that recomputes the total" do
    order = new_order
    assert order.apply_coupon("WELCOME10")
    order.update!(quantity: 4)
    assert_equal BigDecimal("45.00"), order.reload.total
  end

  test "the database itself refuses a second redemption" do
    # Two requests can both pass a Ruby-level check before either saves.
    # Only a unique index on orders.coupon_id makes "works once" true.
    new_order.update_column(:coupon_id, @coupon.id)
    assert_raises(ActiveRecord::RecordNotUnique) do
      new_order.update_column(:coupon_id, @coupon.id)
    end
  end

  test "code is unique regardless of case" do
    assert_not Coupon.new(code: "welcome10", percent_off: 5).valid?
  end

  test "percent_off must be between 1 and 100" do
    assert_not Coupon.new(code: "ZERO", percent_off: 0).valid?
    assert_not Coupon.new(code: "TOOMUCH", percent_off: 101).valid?
    assert Coupon.new(code: "ALL", percent_off: 100).valid?
  end

  test "code is required" do
    assert_not Coupon.new(code: "", percent_off: 10).valid?
  end
end
