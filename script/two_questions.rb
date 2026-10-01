# frozen_string_literal: true
# The same request, the same model, two wordings of the question.
# Run with: bin/rails runner script/two_questions.rb
require "json"

ROW = 17 # a real seller who simply moved to another bank
WORDINGS = {
  "signs of fraud?" => "Does this payout request show signs of fraud or account takeover?",
  "legitimate?" => "Is this a legitimate payout request?"
}.freeze

row = JSON.parse(File.read(Rails.root.join("db/payouts.json"))).find { |r| r["id"] == ROW }
state = PayoutDescription.call(row)
puts "Seller ##{ROW}: real seller, new bank #{row["iban_changed_hours_ago"]} hours ago"
WORDINGS.each do |label, question|
  p_legit = 1 - LayaClient.new.ask(state, question)
  route = if p_legit >= Payouts::RiskEvaluator::PAY_OUT then "pay out"
          elsif p_legit <= Payouts::RiskEvaluator::BLOCK then "BLOCKED"
          else "review"
          end
  puts format("  %-17s p=%.3f  ->  %s", label, p_legit, route)
end
