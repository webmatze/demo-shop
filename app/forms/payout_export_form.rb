class PayoutExportForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :starts_on, :date
  attribute :ends_on, :date
  attr_accessor :seller
  attr_reader :export

  validates :seller, :starts_on, :ends_on, presence: true
  validate :ends_on_is_not_before_starts_on

  def save
    return false unless valid?

    @export = seller.payout_exports.create!(starts_on: starts_on, ends_on: ends_on)
    PayoutExportJob.perform_later(@export)
    true
  end

  private
    def ends_on_is_not_before_starts_on
      return if starts_on.blank? || ends_on.blank? || ends_on >= starts_on

      errors.add(:ends_on, "must be on or after the start date")
    end
end
