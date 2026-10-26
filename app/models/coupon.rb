class Coupon < ApplicationRecord
  belongs_to :order, optional: true

  normalizes :code, with: ->(code) { code.to_s.strip.upcase }

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :percent_off, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 100 }

  def self.find_by_code(code)
    code = code.code if code.is_a?(Coupon)
    find_by(code: code.to_s.strip.upcase)
  end
end