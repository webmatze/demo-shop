class OrdersController < ApplicationController
  before_action :set_order, only: %i[ show apply_coupon apply redeem ]

  # GET /orders
  def index
    @orders = Order.includes(:product).order(created_at: :desc)
  end

  # GET /orders/1
  def show
  end

  # POST /orders
  def create
    @order = Order.create!(order_params)
    redirect_to @order, notice: "Order placed."
  end

  def apply
    apply_coupon
  end

  def redeem
    apply_coupon
  end

  # POST /orders/1/apply_coupon
  def apply_coupon
    @order.apply_coupon(extract_coupon_code)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(@order, partial: "orders/order", locals: { order: @order }),
          turbo_stream.replace("order_#{@order.id}", partial: "orders/order", locals: { order: @order }),
          turbo_stream.replace("coupon_form", partial: "orders/coupon_form", locals: { order: @order }),
          turbo_stream.replace("coupon_form_order_#{@order.id}", partial: "orders/coupon_form", locals: { order: @order })
        ]
      end
      format.html { redirect_to @order }
    end
  end

  private
    def extract_coupon_code
      params[:code] || params[:coupon_code] ||
        params.dig(:coupon, :code) || params.dig(:coupon, :coupon_code) ||
        params.dig(:order, :code) || params.dig(:order, :coupon_code)
    end

  private
    def set_order
      @order = Order.find(params.expect(:id))
    end

    def order_params
      params.expect(order: [ :product_id, :quantity ])
    end
end
