class Order < ApplicationRecord
  belongs_to :product
  has_one :coupon, dependent: :nullify

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  before_validation :compute_total

  def subtotal
    product.price * quantity
  end

  def apply_coupon(code)
    code = code.code if code.is_a?(Coupon)

    if coupon.present?
      errors.add(:coupon, "has already been applied")
      return false
    end

    found = Coupon.find_by_code(code)
    if found.nil?
      errors.add(:coupon, "is invalid")
      return false
    end
    if found.order_id.present?
      errors.add(:coupon, "has already been used")
      return false
    end

    self.coupon = found
    compute_total

    if persisted?
      begin
        transaction do
          found.update!(order: self)
          save!
        end
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved, ActiveRecord::StatementInvalid
        self.coupon = nil
        errors.add(:coupon, "could not be applied")
        return false
      end
    end

    true
  end

  private
    def compute_total
      return unless product && quantity
      base = subtotal
      if coupon
        base = base * (100 - coupon.percent_off) / 100
      end
      self.total = base
    end
end