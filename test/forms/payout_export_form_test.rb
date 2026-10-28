require "test_helper"

class PayoutExportFormTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup { @seller = sellers(:veteran) }

  test "saves a valid range, creates the export and enqueues the job" do
    form = PayoutExportForm.new(seller: @seller, starts_on: "2026-09-01", ends_on: "2026-09-30")

    assert_difference -> { PayoutExport.count }, 1 do
      assert_enqueued_with(job: PayoutExportJob) { assert form.save }
    end
    assert_equal @seller, form.export.seller
    assert_equal [Date.new(2026, 9, 1), Date.new(2026, 9, 30)], [form.export.starts_on, form.export.ends_on]
    assert_not form.export.ready?
  end

  test "a single day is a valid range" do
    form = PayoutExportForm.new(seller: @seller, starts_on: "2026-09-03", ends_on: "2026-09-03")
    assert form.save
  end

  test "ends_on before starts_on is invalid" do
    form = PayoutExportForm.new(seller: @seller, starts_on: "2026-09-30", ends_on: "2026-09-01")

    assert_no_difference -> { PayoutExport.count } do
      assert_no_enqueued_jobs { assert_not form.save }
    end
    assert form.errors[:ends_on].any?
  end

  test "both dates are required" do
    form = PayoutExportForm.new(seller: @seller, starts_on: "", ends_on: nil)

    assert_no_enqueued_jobs { assert_not form.save }
    assert form.errors[:starts_on].any?
    assert form.errors[:ends_on].any?
  end

  test "unparseable dates are rejected without creating an export" do
    form = PayoutExportForm.new(seller: @seller, starts_on: "not a date", ends_on: "2026-09-31")

    assert_no_difference -> { PayoutExport.count } do
      assert_no_enqueued_jobs { assert_not form.save }
    end
    assert form.errors[:starts_on].any?
    assert form.errors[:ends_on].any?
  end
end
