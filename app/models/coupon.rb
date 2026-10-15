class Coupon < ApplicationRecord
  has_one :order

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :percent_off, numericality: { only_integer: true, in: 1..100 }
end
