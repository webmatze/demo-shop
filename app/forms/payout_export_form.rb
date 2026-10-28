class PayoutExportForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :seller
  attr_reader :export

  attribute :starts_on, :date
  attribute :ends_on, :date

  validate :validate_export

  def save
    return false unless valid?

    export.save!
    PayoutExportJob.perform_later(export)
    true
  end

  private
    def validate_export
      @export = PayoutExport.new(seller: seller, starts_on: starts_on, ends_on: ends_on)
      errors.merge!(@export.errors) unless @export.valid?
    end
end
