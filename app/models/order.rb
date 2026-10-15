class Order < ApplicationRecord
  belongs_to :product

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  before_validation :compute_total

  def subtotal
    product.price * quantity
  end

  private
    def compute_total
      self.total = subtotal if product && quantity
    end
end
