class Coupon < ApplicationRecord
  has_one :order

  normalizes :code, with: ->(code) { code.strip.upcase }

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :percent_off, numericality: { only_integer: true, in: 1..100 }

  def self.find_by_code(code)
    find_by(code: code.to_s) if code.present?
  end

  def redeemed?
    order.present?
  end

  def apply_to(amount)
    (amount * (100 - percent_off) / 100).round(2)
  end
end
