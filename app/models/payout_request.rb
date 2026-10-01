class PayoutRequest < ApplicationRecord
  STATES = %w[open approved review blocked].freeze

  belongs_to :seller

  validates :amount, numericality: { greater_than: 0 }
  validates :state, inclusion: { in: STATES }

  scope :waiting, -> { where(state: %w[open review]).order(created_at: :desc) }

  broadcasts_to ->(_request) { "payouts" }, inserts_by: :prepend

  # The request as one paragraph -- the same text the generator wrote and
  # the same text the model scored when we measured the thresholds.
  def to_state
    PayoutDescription.call(
      "account_age_days" => seller.account_age_days, "orders" => seller.orders,
      "lifetime_sales" => seller.lifetime_sales,
      "days_since_last_order" => seller.days_since_last_order,
      "iban_changed_hours_ago" => seller.iban_changed_hours_ago,
      "login_country" => seller.login_country, "request_country" => request_country,
      "via_proxy" => via_proxy, "amount" => amount
    )
  end

  def decide!(state, probability:, reason:)
    update!(state: state, probability: probability, reason: reason)
  end
end
