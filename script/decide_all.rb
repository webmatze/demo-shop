# frozen_string_literal: true
# Applies the thresholds that are in the code right now to the recorded run of
# all hundred requests. Run with: bin/rails runner script/decide_all.rb
require "json"

rows = JSON.parse(File.read(Rails.root.join("db/run-laya-2026-10-02.json")))
rows.each { |r| r["legit"] = 1 - r["p"] }
pay = Payouts::RiskEvaluator::PAY_OUT
block = Payouts::RiskEvaluator::BLOCK

auto = rows.select { |r| r["legit"] >= pay }
stop = rows.select { |r| r["legit"] <= block }
human = rows - auto - stop
puts "thresholds in the code: pay out from #{pay}, block up to #{block}"
puts format("  paid out  %3d   wrong %d", auto.size, auto.count { |r| r["fraud"] })
puts format("  blocked   %3d   wrong %d", stop.size, stop.count { |r| !r["fraud"] })
puts format("  reviewed  %3d", human.size)
