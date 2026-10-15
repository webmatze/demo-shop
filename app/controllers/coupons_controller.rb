class CouponsController < ApplicationController
  # POST /orders/1/coupon
  def create
    @order = Order.find(params[:order_id])

    if @order.apply_coupon(params[:code])
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @order, notice: "Coupon applied." }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { render "orders/show", status: :unprocessable_entity }
      end
    end
  end
end
