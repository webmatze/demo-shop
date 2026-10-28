require "test_helper"
require "csv"

class PayoutExportTest < ActiveSupport::TestCase
  setup { @seller = sellers(:veteran) }

  test "validates the seller and date range" do
    export = PayoutExport.new
    assert_not export.valid?
    assert export.errors[:seller].any?
    assert export.errors[:starts_on].any?
    assert export.errors[:ends_on].any?

    export.assign_attributes(seller: @seller, starts_on: Date.new(2026, 9, 30), ends_on: Date.new(2026, 9, 1))
    assert_not export.valid?
    assert export.errors[:ends_on].any?

    export.ends_on = export.starts_on
    assert export.valid?
  end

  test "exports the whole local day with CSV quoting and stable order" do
    Time.use_zone("Eastern Time (US & Canada)") do
      day = Date.new(2026, 11, 1) # daylight saving time ends on this day
      start = day.in_time_zone.beginning_of_day
      finish = (day + 1.day).in_time_zone.beginning_of_day
      @seller.payout_requests.create!(amount: 10, state: "open", created_at: start - 1.second)
      first = @seller.payout_requests.create!(amount: 20, state: "approved", reason: "one,\ntwo", created_at: start)
      second = @seller.payout_requests.create!(amount: 30, state: "review", created_at: start)
      last = @seller.payout_requests.create!(amount: 40, state: "blocked", created_at: finish - 1.second)
      @seller.payout_requests.create!(amount: 50, state: "open", created_at: finish)
      sellers(:newcomer).payout_requests.create!(amount: 60, state: "open", created_at: start)

      export = PayoutExport.create!(seller: @seller, starts_on: day, ends_on: day)
      assert_not export.ready?
      export.generate_csv!

      assert export.ready?
      rows = CSV.parse(export.csv, headers: true)
      assert_equal [ first.amount, second.amount, last.amount ].map(&:to_s), rows.map { _1["amount"] }
      assert_equal [ "2026-11-01" ] * 3, rows.map { _1["date"] }
      assert_equal "one,\ntwo", rows.first["reason"]
    end
  end
end
