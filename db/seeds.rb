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

# One order, so the orders page is not empty.
Order.find_or_create_by!(product: Product.find_by!(name: "Ruby Mug")) { |o| o.quantity = 2 }

# Two sellers with a payout history over several months, for the payout
# export: Clara gets paid every few weeks, Max is new and was stopped once.
{
  "Clara Wolf" => { account_age_days: 1274, orders: 356, lifetime_sales: 73692, days_since_last_order: 1,
                    login_country: "Germany",
                    payouts: [["2026-08-04", 412, "approved"], ["2026-08-25", 389, "approved"],
                              ["2026-09-03", 607, "approved"], ["2026-09-22", 451, "approved"],
                              ["2026-10-06", 528, "review"]] },
  "Max Brandt" => { account_age_days: 6, orders: 1, lifetime_sales: 25, days_since_last_order: 0,
                    login_country: "Germany",
                    payouts: [["2026-09-14", 2417, "blocked"], ["2026-10-02", 120, "open"]] }
}.each do |name, attrs|
  payouts = attrs.delete(:payouts)
  seller = Seller.find_or_create_by!(name: name) { |s| s.assign_attributes(attrs) }
  next if seller.payout_requests.any?

  payouts.each do |day, amount, state|
    at = Time.zone.parse("#{day} 10:00")
    seller.payout_requests.create!(amount: amount, state: state, request_country: attrs[:login_country],
                                   created_at: at, updated_at: at)
  end
end
