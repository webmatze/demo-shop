class OrdersController < ApplicationController
  # GET /orders
  def index
    @orders = Order.includes(:product).order(created_at: :desc)
  end

  # GET /orders/1
  def show
    @order = Order.find(params.expect(:id))
  end

  # POST /orders
  def create
    @order = Order.create!(order_params)
    redirect_to @order, notice: "Order placed."
  end

  private
    def order_params
      params.expect(order: [ :product_id, :quantity ])
    end
end
