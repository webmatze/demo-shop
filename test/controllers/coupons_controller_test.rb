require "test_helper"

class CouponsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @order = Order.create!(product: products(:one), quantity: 2)
  end

  test "order page has a coupon form" do
    get order_path(@order)
    assert_response :success
    assert_select "#coupon_form form[action=?]", order_coupon_path(@order) do
      assert_select "input[name=?]", "code"
    end
  end

  # --- HTML ---

  test "applies a coupon and redirects to the order" do
    post order_coupon_path(@order), params: { code: "welcome10" }

    assert_redirected_to order_path(@order)
    assert_equal "Coupon applied.", flash[:notice]
    assert_equal BigDecimal("22.50"), @order.reload.total
    assert_equal coupons(:welcome10), @order.coupon
  end

  test "unknown code renders the error with 422" do
    post order_coupon_path(@order), params: { code: "NOPE" }

    assert_response :unprocessable_entity
    assert_match "is not valid", response.body
    assert_nil @order.reload.coupon_id
  end

  test "code used by another order renders the error with 422" do
    other = Order.create!(product: products(:two), quantity: 1)
    assert other.apply_coupon("WELCOME10")

    post order_coupon_path(@order), params: { code: "WELCOME10" }

    assert_response :unprocessable_entity
    assert_match "has already been used", response.body
    assert_equal BigDecimal("25.00"), @order.reload.total
  end

  test "second coupon on the same order renders the error with 422" do
    assert @order.apply_coupon("WELCOME10")

    post order_coupon_path(@order), params: { code: "HALF" }

    assert_response :unprocessable_entity
    assert_match "already applied to this order", response.body
    assert_equal BigDecimal("22.50"), @order.reload.total
  end

  # --- Turbo Stream ---

  test "turbo stream success replaces the order with the new total" do
    post order_coupon_path(@order), params: { code: "WELCOME10" }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[action=replace][target=?]", "order_#{@order.id}" do
      assert_select "template", /\$22\.50/
    end
  end

  test "turbo stream failure updates the coupon form with the error" do
    post order_coupon_path(@order), params: { code: "NOPE" }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[target=?]", "coupon_form" do
      assert_select "template", /is not valid/
    end
    assert_nil @order.reload.coupon_id
  end

  test "turbo stream failure for a redeemed code shows the error" do
    other = Order.create!(product: products(:two), quantity: 1)
    assert other.apply_coupon("WELCOME10")

    post order_coupon_path(@order), params: { code: "WELCOME10" }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_select "turbo-stream[target=?]", "coupon_form" do
      assert_select "template", /has already been used/
    end
  end
end
