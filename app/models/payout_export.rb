class PayoutExport < ApplicationRecord
  belongs_to :seller

  validates :starts_on, :ends_on, presence: true

  def ready?
    csv.present?
  end
end
