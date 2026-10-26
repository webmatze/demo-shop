class CouponsController < ApplicationController
  def create
    @order = Order.find(params[:order_id] || params[:id])
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
end