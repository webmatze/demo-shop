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
end
