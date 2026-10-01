class Seller < ApplicationRecord
  has_many :payout_requests, dependent: :destroy

  validates :name, presence: true
end
