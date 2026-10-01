mugs = Category.find_or_create_by!(name: "Mugs")
apparel = Category.find_or_create_by!(name: "Apparel")
stickers = Category.find_or_create_by!(name: "Stickers")
Product.find_or_create_by!(name: "Ruby Mug") { |p| p.price = 12.50; p.description = "A mug for Rubyists."; p.category = mugs }
Product.find_or_create_by!(name: "Rails T-Shirt") { |p| p.price = 24.00; p.description = "Red, of course."; p.category = apparel }
Product.find_or_create_by!(name: "Screencast Sticker Pack") { |p| p.price = 4.90; p.description = "Ten stickers."; p.category = stickers }

# Sellers and payout requests for the compliance page: the first eight rows
# of db/payouts.json, so the queue is not empty.
require "json"
JSON.parse(File.read(Rails.root.join("db/payouts.json"))).first(8).each do |row|
  seller = Seller.find_or_create_by!(name: "Seller ##{row["id"]}") do |s|
    s.account_age_days = row["account_age_days"]
    s.orders = row["orders"]
    s.lifetime_sales = row["lifetime_sales"]
    s.days_since_last_order = row["days_since_last_order"]
    s.iban_changed_hours_ago = row["iban_changed_hours_ago"]
    s.login_country = row["login_country"]
  end
  next if seller.payout_requests.any?

  seller.payout_requests.create!(amount: row["amount"], request_country: row["request_country"],
                                 via_proxy: row["via_proxy"])
end
