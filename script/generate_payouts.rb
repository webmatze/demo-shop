# frozen_string_literal: true

# A hundred payout requests with ground truth. Nobody may publish real payout
# data, so this script makes it -- in the open: the rules are right here, and
# the model never sees them. It reads the same paragraph a reviewer would.
#
# That makes this a fair test of the model and a poor test of your business.
# Measure on your own labelled requests before you trust any threshold.
require "json"

RNG = Random.new(20261002)
def pick(a) = a[RNG.rand(a.size)]
def between(a, b) = a + RNG.rand(b - a + 1)

HOME = "Germany"
ABROAD = ["Spain", "Italy", "Portugal", "Turkey", "Poland"].freeze
FAR = ["Nigeria", "Vietnam", "Ukraine", "Belarus", "Brazil"].freeze

def base(age, orders, sales, last_order)
  { "account_age_days" => age, "orders" => orders, "lifetime_sales" => sales,
    "days_since_last_order" => last_order, "iban_changed_hours_ago" => nil,
    "login_country" => HOME, "request_country" => HOME, "via_proxy" => false }
end

PROFILES = {
  # --- legitimate ----------------------------------------------------------
  "established" => [35, lambda {
    age = between(400, 2200); orders = between(60, 500)
    base(age, orders, orders * between(90, 220), between(0, 6))
      .merge("amount" => between(300, 4000))
  }],
  "new_but_real" => [10, lambda {
    age = between(12, 60); orders = between(8, 40)
    base(age, orders, orders * between(70, 160), between(0, 3))
      .merge("amount" => between(200, 1500))
  }],
  # New bank account on an old seller account -- looks bad, is not.
  "bank_change" => [10, lambda {
    age = between(400, 2200); orders = between(60, 400)
    base(age, orders, orders * between(90, 220), between(0, 5))
      .merge("iban_changed_hours_ago" => between(3, 40), "amount" => between(300, 3000))
  }],
  # Seller on holiday -- country changes, nothing else does.
  "travelling" => [10, lambda {
    age = between(400, 2200); orders = between(60, 400)
    base(age, orders, orders * between(90, 220), between(0, 8))
      .merge("request_country" => pick(ABROAD), "amount" => between(300, 3000))
  }],
  # --- fraud ---------------------------------------------------------------
  # Account takeover: old and good, but bank and country flip at the same time.
  "takeover" => [12, lambda {
    age = between(400, 2200); orders = between(60, 400)
    base(age, orders, orders * between(90, 220), between(0, 4))
      .merge("iban_changed_hours_ago" => between(1, 20), "request_country" => pick(FAR),
             "via_proxy" => true, "amount" => between(1500, 5000))
  }],
  # Fresh account, almost no sales, large payout.
  "fast_cash" => [12, lambda {
    age = between(1, 13); orders = between(0, 2)
    base(age, orders, orders * between(20, 90), between(0, 2))
      .merge("amount" => between(1200, 5000))
  }],
  # Money mule: some sales, but the payout does not match them.
  "mule" => [11, lambda {
    age = between(20, 90); orders = between(3, 12); sales = orders * between(40, 110)
    base(age, orders, sales, between(0, 3))
      .merge("iban_changed_hours_ago" => between(2, 30), "request_country" => pick(FAR),
             "via_proxy" => true, "amount" => sales * between(3, 8))
  }]
}.freeze

FRAUD = %w[takeover fast_cash mule].freeze

rows = []
PROFILES.each do |name, (count, build)|
  count.times { rows << build.call.merge("profile" => name, "fraud" => FRAUD.include?(name)) }
end
rows = rows.shuffle(random: RNG).each_with_index.map { |r, i| { "id" => i + 1 }.merge(r) }

File.write(File.expand_path("../db/payouts.json", __dir__), "#{JSON.pretty_generate(rows)}\n")
puts "#{rows.size} requests, #{rows.count { |r| r["fraud"] }} of them fraud"
puts rows.group_by { |r| r["profile"] }.transform_values(&:size).inspect
