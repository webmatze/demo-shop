require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  test "places an order from a product" do
    assert_difference("Order.count") do
      post orders_path, params: { order: { product_id: products(:one).id, quantity: 1 } }
    end
    assert_redirected_to order_path(Order.last)
  end

  test "shows an order" do
    order = Order.create!(product: products(:two), quantity: 1)
    get order_path(order)
    assert_response :success
    assert_match "$24.00", response.body
  end

  test "lists orders" do
    Order.create!(product: products(:one), quantity: 1)
    get orders_path
    assert_response :success
    assert_select "#orders .card", 1
  end
  test "order page has a coupon form" do
    order = Order.create!(product: products(:one), quantity: 1)
    get order_path(order)
    assert_response :success
    assert_select "form[action=?]", apply_coupon_order_path(order)
    assert_select "input[name=?]", "code"
  end

  test "applying a coupon via turbo stream updates the total" do
    order = Order.create!(product: products(:one), quantity: 2)
    post apply_coupon_order_path(order), params: { code: "WELCOME10" }, as: :turbo_stream
    assert_response :success
    assert_equal Mime[:turbo_stream], response.media_type
    assert_match "$22.50", response.body
    assert_match /<turbo-stream/, response.body
  end
end
