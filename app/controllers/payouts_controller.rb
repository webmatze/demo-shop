class PayoutsController < ApplicationController
  DEMO_IDS = [44, 51, 23].freeze

  def index
    @requests = PayoutRequest.includes(:seller).order(created_at: :desc).limit(25)
  end

  # Three requests out of db/payouts.json, straight into the queue. Demo
  # furniture: in a real shop the sellers press the button themselves.
  def simulate
    rows = JSON.parse(File.read(Rails.root.join("db/payouts.json"))).index_by { |r| r["id"] }
    DEMO_IDS.each do |id|
      row = rows.fetch(id)
      seller = Seller.create!(
        name: "Seller ##{id}", account_age_days: row["account_age_days"], orders: row["orders"],
        lifetime_sales: row["lifetime_sales"], days_since_last_order: row["days_since_last_order"],
        iban_changed_hours_ago: row["iban_changed_hours_ago"], login_country: row["login_country"]
      )
      request = seller.payout_requests.create!(amount: row["amount"], request_country: row["request_country"],
                                               via_proxy: row["via_proxy"])
      EvaluatePayoutRiskJob.perform_later(request)
    end
    redirect_to payouts_path
  end
end
