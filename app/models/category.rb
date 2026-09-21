class Category < ApplicationRecord
  has_many :products, dependent: :nullify

  validates :name, presence: true, length: { minimum: 3 }, uniqueness: { case_sensitive: false }
end
