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
end
