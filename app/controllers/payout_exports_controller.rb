class PayoutExportsController < ApplicationController
  before_action :set_seller

  def index
    @form = PayoutExportForm.new(seller: @seller)
    load_exports
  end

  def create
    @form = PayoutExportForm.new(export_params.merge(seller: @seller))
    if @form.save
      redirect_to seller_payout_exports_path(@seller), notice: "Export requested."
    else
      load_exports
      render :index, status: :unprocessable_content
    end
  end

  def show
    export = @seller.payout_exports.find(params[:id])
    return head :not_found unless export.ready?

    send_data export.csv, type: "text/csv", disposition: "attachment", filename: "payout-export-#{export.id}.csv"
  end

  private
    def set_seller
      @seller = Seller.find(params[:seller_id])
    end

    def load_exports
      @exports = @seller.payout_exports.order(created_at: :desc, id: :desc)
    end

    def export_params
      params.expect(payout_export: [ :starts_on, :ends_on ])
    end
end
