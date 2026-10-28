class Seller < ApplicationRecord
  has_many :payout_requests, dependent: :destroy
  has_many :payout_exports, dependent: :destroy

  validates :name, presence: true
end
