require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "total is price times quantity" do
    order = Order.create!(product: products(:one), quantity: 2)
    assert_equal 25.00, order.total
  end

  test "quantity must be positive" do
    order = Order.new(product: products(:one), quantity: 0)
    assert_not order.valid?
    assert_includes order.errors[:quantity], "must be greater than 0"
  end

  test "apply_coupon returns true and reduces total the first time" do
    order = Order.create!(product: products(:one), quantity: 2)
    assert order.apply_coupon("WELCOME10")
    assert_equal 22.50, order.total
  end

  test "apply_coupon returns false with errors on second call" do
    order = Order.create!(product: products(:one), quantity: 2)
    assert order.apply_coupon("WELCOME10")
    assert_not order.apply_coupon("WELCOME10")
    assert order.errors[:coupon].present?
  end

  test "an order has at most one coupon" do
    order = Order.create!(product: products(:one), quantity: 1)
    assert order.apply_coupon("WELCOME10")
    assert_not order.apply_coupon("SAVE20")
    assert_equal "WELCOME10", order.coupon.code
  end

  test "a coupon code works only once across orders" do
    first_order = Order.create!(product: products(:one), quantity: 1)
    second_order = Order.create!(product: products(:one), quantity: 1)
    assert first_order.apply_coupon("WELCOME10")
    assert_not second_order.apply_coupon("WELCOME10")
    assert second_order.errors[:coupon].present?
  end

  test "apply_coupon returns false for an invalid code" do
    order = Order.create!(product: products(:one), quantity: 1)
    assert_not order.apply_coupon("DOESNOTEXIST")
    assert order.errors[:coupon].present?
  end
end
