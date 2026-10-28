require "csv"

class PayoutExport < ApplicationRecord
  belongs_to :seller

  validates :starts_on, :ends_on, presence: true
  validates :ends_on, comparison: { greater_than_or_equal_to: :starts_on }, if: -> { starts_on.present? && ends_on.present? }

  def ready?
    csv.present?
  end

  def generate_csv!
    from = starts_on.in_time_zone.beginning_of_day
    until_time = (ends_on + 1.day).in_time_zone.beginning_of_day
    requests = seller.payout_requests.where(created_at: from...until_time).order(:created_at, :id)

    content = CSV.generate do |csv|
      csv << %w[date amount state reason]
      requests.each do |request|
        csv << [ request.created_at.in_time_zone.to_date.iso8601, request.amount, request.state, request.reason ]
      end
    end
    update!(csv: content)
  end
end
