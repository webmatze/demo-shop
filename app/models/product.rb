class Product < ApplicationRecord
  belongs_to :category, optional: true

  normalizes :name, with: ->(name) { name.strip.squeeze(" ") }

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :price, presence: true, numericality: { greater_than: 0 }
end
