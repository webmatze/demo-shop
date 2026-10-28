require "test_helper"
require "csv"

class PayoutExportJobTest < ActiveJob::TestCase
  setup do
    @seller = sellers(:veteran)
    PayoutRequest.where(seller: @seller).delete_all
    add_request(@seller, "2026-08-31 23:30", 100, "approved")   # the day before
    add_request(@seller, "2026-09-22 09:00", 451, "approved")
    add_request(@seller, "2026-09-03 10:00", 607, "review", reason: "IBAN changed, same country")
    add_request(@seller, "2026-09-30 22:00", 288, "open")       # the last day counts
    add_request(@seller, "2026-10-01 00:30", 999, "open")       # the day after
    add_request(sellers(:newcomer), "2026-09-14 12:00", 2417, "blocked")
    @export = PayoutExport.create!(seller: @seller, starts_on: Date.new(2026, 9, 1), ends_on: Date.new(2026, 9, 30))
  end

  test "builds the CSV of this seller's requests in the range, oldest first" do
    PayoutExportJob.perform_now(@export)
    @export.reload

    assert @export.ready?
    rows = CSV.parse(@export.csv, headers: true)
    assert_equal %w[date amount state reason], rows.headers
    assert_equal %w[2026-09-03 2026-09-22 2026-09-30], rows.map { _1["date"] }
    assert_equal %w[607 451 288], rows.map { _1["amount"] }
    assert_equal "IBAN changed, same country", rows.first["reason"]
  end

  test "an empty range still gives a CSV with the header" do
    empty = PayoutExport.create!(seller: @seller, starts_on: Date.new(2025, 1, 1), ends_on: Date.new(2025, 1, 31))
    PayoutExportJob.perform_now(empty)

    assert empty.reload.ready?
    assert_equal ["date,amount,state,reason"], empty.csv.lines.map(&:chomp)
  end

  private
    def add_request(seller, at, amount, state, reason: nil)
      time = Time.zone.parse(at)
      seller.payout_requests.create!(amount: amount, state: state, reason: reason, request_country: "Germany",
                                     created_at: time, updated_at: time)
    end
end
