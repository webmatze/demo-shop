class PayoutExportJob < ApplicationJob
  def perform(export)
    export.generate_csv!
    export.broadcast_replace_to export.seller, :payout_exports, partial: "payout_exports/payout_export", locals: { payout_export: export }
  end
end
