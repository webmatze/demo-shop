class Order < ApplicationRecord
  belongs_to :product
  belongs_to :coupon, optional: true

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  before_validation :compute_total

  def subtotal
    product.price * quantity
  end

  def apply_coupon(code)
    errors.delete(:coupon)

    if coupon_id.present?
      errors.add(:coupon, "has already been redeemed")
      return false
    end

    selected_coupon = Coupon.find_by("lower(code) = ?", code.to_s.downcase)
    unless selected_coupon
      errors.add(:coupon, "is not valid")
      return false
    end

    if Order.exists?(coupon_id: selected_coupon.id)
      errors.add(:coupon, "has already been redeemed")
      return false
    end

    self.coupon = selected_coupon
    return true if save

    self.coupon = nil
    compute_total
    false
  rescue ActiveRecord::RecordNotUnique
    reload if persisted?
    errors.add(:coupon, "has already been redeemed")
    false
  end

  private
    def compute_total
      return unless product && quantity

      self.total = subtotal
      self.total = total * (100 - coupon.percent_off) / 100 if coupon
    end
end
