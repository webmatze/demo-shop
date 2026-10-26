require "test_helper"

class CouponTest < ActiveSupport::TestCase
  # --- Coupon validations ---

  test "fixture coupons are valid" do
    assert coupons(:welcome10).valid?
    assert coupons(:half).valid?
  end

  test "code must be present" do
    coupon = Coupon.new(code: "", percent_off: 10)
    assert_not coupon.valid?
    assert_not_empty coupon.errors[:code]
  end

  test "code is unique regardless of case" do
    coupon = Coupon.new(code: "welcome10", percent_off: 20)
    assert_not coupon.valid?
    assert_not_empty coupon.errors[:code]
  end

  test "percent_off 0 is invalid" do
    coupon = Coupon.new(code: "ZERO", percent_off: 0)
    assert_not coupon.valid?
    assert_not_empty coupon.errors[:percent_off]
  end

  test "percent_off 101 is invalid" do
    coupon = Coupon.new(code: "TOOMUCH", percent_off: 101)
    assert_not coupon.valid?
    assert_not_empty coupon.errors[:percent_off]
  end

  test "percent_off must be an integer" do
    coupon = Coupon.new(code: "FRACTION", percent_off: 10.5)
    assert_not coupon.valid?
    assert_not_empty coupon.errors[:percent_off]
  end

  test "percent_off 1 and 100 are valid" do
    assert Coupon.new(code: "ONE", percent_off: 1).valid?
    assert Coupon.new(code: "FREE", percent_off: 100).valid?
  end

  # --- Coupon.find_by_code ---

  test "find_by_code is case-insensitive and strips whitespace" do
    assert_equal coupons(:welcome10), Coupon.find_by_code("welcome10")
    assert_equal coupons(:welcome10), Coupon.find_by_code("  Welcome10 ")
  end

  test "find_by_code returns nil for an unknown code" do
    assert_nil Coupon.find_by_code("NOPE")
  end

  # --- Order#apply_coupon ---

  test "contract: second apply of the same code fails" do
    order = Order.create!(product: products(:one), quantity: 2)

    assert order.apply_coupon("WELCOME10")
    assert_equal BigDecimal("22.50"), order.total

    assert_not order.apply_coupon("WELCOME10")
    assert_not_empty order.errors[:coupon]
  end

  test "apply_coupon reduces the total and persists the coupon" do
    order = Order.create!(product: products(:one), quantity: 2)

    assert order.apply_coupon("WELCOME10")

    order.reload
    assert_equal coupons(:welcome10), order.coupon
    assert_equal BigDecimal("22.50"), order.total
    assert coupons(:welcome10).reload.redeemed?
  end

  test "apply_coupon is case-insensitive" do
    order = Order.create!(product: products(:one), quantity: 2)

    assert order.apply_coupon("welcome10")
    assert_equal coupons(:welcome10), order.reload.coupon
  end

  test "coupon is not redeemed before it is applied" do
    assert_not coupons(:welcome10).redeemed?
  end

  test "unknown code fails with an error" do
    order = Order.create!(product: products(:one), quantity: 2)

    assert_not order.apply_coupon("NOPE")
    assert_includes order.errors[:coupon], "is not valid"
  end

  test "same code on a second order fails" do
    first = Order.create!(product: products(:one), quantity: 2)
    second = Order.create!(product: products(:two), quantity: 1)
    assert first.apply_coupon("WELCOME10")

    assert_not second.apply_coupon("WELCOME10")
    assert_includes second.errors[:coupon], "has already been used"
  end

  test "an order already holding a coupon cannot take another" do
    order = Order.create!(product: products(:one), quantity: 2)
    assert order.apply_coupon("WELCOME10")

    assert_not order.apply_coupon("HALF")
    assert_includes order.errors[:coupon], "already applied to this order"
    assert_not coupons(:half).reload.redeemed?
  end

  test "failed apply leaves the order unchanged in the database" do
    order = Order.create!(product: products(:one), quantity: 2)
    other = Order.create!(product: products(:two), quantity: 1)
    assert other.apply_coupon("HALF")

    assert_not order.apply_coupon("NOPE")
    assert_not order.apply_coupon("HALF")

    order.reload
    assert_nil order.coupon_id
    assert_equal BigDecimal("25.00"), order.total
  end

  test "failed second coupon keeps the first discount in the database" do
    order = Order.create!(product: products(:one), quantity: 2)
    assert order.apply_coupon("WELCOME10")

    assert_not order.apply_coupon("HALF")

    order.reload
    assert_equal coupons(:welcome10).id, order.coupon_id
    assert_equal BigDecimal("22.50"), order.total
  end

  test "50 percent off halves the total" do
    order = Order.create!(product: products(:two), quantity: 1)

    assert order.apply_coupon("HALF")
    assert_equal BigDecimal("12.00"), order.reload.total
  end

  test "100 percent off makes the total zero" do
    Coupon.create!(code: "FREE", percent_off: 100)
    order = Order.create!(product: products(:one), quantity: 2)

    assert order.apply_coupon("FREE")
    assert_equal BigDecimal("0.00"), order.reload.total
  end

  test "discounted total is rounded to cents" do
    Coupon.create!(code: "THIRD", percent_off: 33)
    order = Order.create!(product: products(:one), quantity: 1)

    assert order.apply_coupon("THIRD")
    # 12.50 * 67 / 100 = 8.375 -> 8.38
    assert_equal BigDecimal("8.38"), order.reload.total
    assert_kind_of BigDecimal, order.total
  end

  test "discount survives a later save" do
    order = Order.create!(product: products(:one), quantity: 2)
    assert order.apply_coupon("WELCOME10")

    order.reload.save!
    assert_equal BigDecimal("22.50"), order.reload.total
  end
end
