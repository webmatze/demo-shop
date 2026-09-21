class ProductForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :price, :decimal
  attribute :description, :string
  attribute :category_name, :string

  validates :category_name, presence: true, length: { minimum: 3 }
  validate { errors.merge!(product.errors) unless product.valid? }

  def save
    return false unless valid?

    ApplicationRecord.transaction do
      product.category = Category.find_or_create_by!(name: category_name.strip)
      product.save!
    end
    true
  end

  def product
    @product ||= Product.new(name: name, price: price, description: description)
  end
end
