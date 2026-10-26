class Order < ApplicationRecord
  belongs_to :product
  belongs_to :coupon, optional: true

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  before_validation :compute_total

  def subtotal
    product.price * quantity
  end

  # A coupon code works once: across all orders, and an order holds at most one.
  def apply_coupon(code)
    errors.delete(:coupon)
    return fail_coupon("already applied to this order") if coupon_id_in_database

    found = Coupon.find_by_code(code)
    return fail_coupon("is not valid") unless found
    return fail_coupon("has already been used") if found.redeemed?

    self.coupon = found
    save || rollback_coupon
  rescue ActiveRecord::RecordNotUnique
    rollback_coupon
    fail_coupon("has already been used")
  end

  private
    def compute_total
      return unless product && quantity
      self.total = coupon ? coupon.apply_to(subtotal) : subtotal
    end

    def fail_coupon(message)
      errors.add(:coupon, message)
      false
    end

    def rollback_coupon
      self.coupon = nil
      restore_attributes([ "total" ])
      false
    end
end
