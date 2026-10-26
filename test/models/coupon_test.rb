require "test_helper"

class CouponTest < ActiveSupport::TestCase
  test "code is normalized to uppercase" do
    coupon = Coupon.create!(code: "  casetest  ", percent_off: 10)
    assert_equal "CASETEST", coupon.code
  end

  test "code is case-insensitive" do
    Coupon.create!(code: "Mixed", percent_off: 5)
    duplicate = Coupon.new(code: "mixed", percent_off: 5)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:code], "has already been taken"
  end

  test "code must be present" do
    coupon = Coupon.new(code: "", percent_off: 5)
    assert_not coupon.valid?
    assert_includes coupon.errors[:code], "can't be blank"
  end

  test "percent_off must be between 1 and 100" do
    assert Coupon.new(code: "A", percent_off: 1).valid?
    assert Coupon.new(code: "B", percent_off: 100).valid?
    invalid_low = Coupon.new(code: "C", percent_off: 0)
    assert_not invalid_low.valid?
    assert_includes invalid_low.errors[:percent_off], "must be greater than or equal to 1"
    invalid_high = Coupon.new(code: "D", percent_off: 101)
    assert_not invalid_high.valid?
    assert_includes invalid_high.errors[:percent_off], "must be less than or equal to 100"
  end

  test "percent_off must be an integer" do
    coupon = Coupon.new(code: "E", percent_off: 5.5)
    assert_not coupon.valid?
    assert_includes coupon.errors[:percent_off], "must be an integer"
  end

  test "find_by_code is case-insensitive" do
    coupon = coupons(:welcome)
    assert_equal coupon, Coupon.find_by_code("welcome10")
    assert_equal coupon, Coupon.find_by_code("  WELCOME10  ")
  end
end
