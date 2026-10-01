# frozen_string_literal: true
# Which threshold costs least? Measured on the hundred labelled requests;
# a wrong approval loses the actual payout amount, a review costs 12 EUR.
require "json"

REVIEW = 12.0
root = File.expand_path("..", __dir__)
amounts = JSON.parse(File.read("#{root}/db/payouts.json")).to_h { |r| [r["id"], r["amount"]] }
rows = JSON.parse(File.read("#{root}/db/run-laya-2026-10-02.json"))
rows.each { |r| r["legit"] = 1 - r["p"] }

puts "pay out from   auto   wrong      loss   reviews    cost"
[0.80, 0.82, 0.84, 0.85, 0.86, 0.98].each do |t|
  auto = rows.select { |r| r["legit"] >= t }
  wrong = auto.select { |r| r["fraud"] }
  loss = wrong.sum { |r| amounts[r["id"]] }
  reviews = rows.size - auto.size
  puts format("        %.2f    %3d     %2d   %7d E   %3d   %6d E",
              t, auto.size, wrong.size, loss, reviews, loss + reviews * REVIEW)
end
