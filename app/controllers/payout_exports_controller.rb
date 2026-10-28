class PayoutExportsController < ApplicationController
  before_action :set_seller

  def index
    @form = PayoutExportForm.new(seller: @seller)
    @exports = @seller.payout_exports.order(created_at: :desc)
  end

  def create
    @form = PayoutExportForm.new(form_params.merge(seller: @seller))

    if @form.save
      redirect_to seller_payout_exports_path(@seller), notice: "Export requested."
    else
      @exports = @seller.payout_exports.order(created_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  def show
    export = @seller.payout_exports.find(params[:id])
    send_data export.csv.to_s, filename: "payout-export-#{export.id}.csv", type: "text/csv", disposition: :attachment
  end

  private
    def set_seller
      @seller = Seller.find(params[:seller_id])
    end

    def form_params
      params.expect(payout_export: [ :starts_on, :ends_on ]).to_h.symbolize_keys
    end
end
