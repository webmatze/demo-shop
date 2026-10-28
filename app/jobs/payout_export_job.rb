require "csv"

class PayoutExportJob < ApplicationJob
  queue_as :default

  def perform(export)
    requests = export.seller.payout_requests
                     .where(created_at: export.starts_on.beginning_of_day..export.ends_on.end_of_day)
                     .order(:created_at, :id)

    csv = CSV.generate(headers: %w[date amount state reason], write_headers: true) do |rows|
      requests.each do |request|
        rows << [request.created_at.to_date.iso8601, request.amount, request.state, request.reason]
      end
    end

    export.update!(csv: csv)
    export.broadcast_replace_to(export.seller, :payout_exports)
  end
end
