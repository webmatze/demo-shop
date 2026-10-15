require "test_helper"

# Contract for Part B:
#   resources :orders do resource :coupon, only: :create end
#   POST /orders/:order_id/coupon  params: { code: "..." }
#   Turbo Stream: replaces the order card (dom_id order) and shows errors.
#   HTML fallback: redirect to the order on success, 422 on failure.
class CouponsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Coupon.create!(code: "WELCOME10", percent_off: 10)
    @order = Order.create!(product: products(:one), quantity: 2) # $25.00
  end

  test "the order page has a coupon form" do
    get order_path(@order)
    assert_response :success
    assert_select "form[action=?]", order_coupon_path(@order) do
      assert_select "input[name=?]", "code"
    end
  end

  test "applying a code updates the total via turbo stream" do
    post order_coupon_path(@order), params: { code: "WELCOME10" }, as: :turbo_stream
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[target=?]", dom_id(@order)
    assert_match "$22.50", response.body
    assert_equal BigDecimal("22.50"), @order.reload.total
  end

  test "a redeemed code shows the error via turbo stream" do
    other = Order.create!(product: products(:one), quantity: 1)
    assert other.apply_coupon("WELCOME10")

    post order_coupon_path(@order), params: { code: "WELCOME10" }, as: :turbo_stream
    assert_response :unprocessable_entity
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match "has already been redeemed", response.body
    assert_equal BigDecimal("25.00"), @order.reload.total
  end

  test "an unknown code shows the error via turbo stream" do
    post order_coupon_path(@order), params: { code: "NOPE" }, as: :turbo_stream
    assert_response :unprocessable_entity
    assert_match "is not valid", response.body
  end

  test "html fallback redirects to the order on success" do
    post order_coupon_path(@order), params: { code: "WELCOME10" }
    assert_redirected_to order_path(@order)
    assert_equal BigDecimal("22.50"), @order.reload.total
  end

  test "html fallback renders the error on failure" do
    post order_coupon_path(@order), params: { code: "NOPE" }
    assert_response :unprocessable_entity
    assert_match "is not valid", response.body
  end
end
