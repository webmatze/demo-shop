require "test_helper"

class PayoutExportsControllerTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  setup { @seller = sellers(:veteran) }

  test "the export page has the seller's name, a form and the list" do
    get seller_payout_exports_path(@seller)

    assert_response :success
    assert_match @seller.name, response.body
    assert_select "form[action=?]", seller_payout_exports_path(@seller) do
      assert_select "input[name=?]", "payout_export[starts_on]"
      assert_select "input[name=?]", "payout_export[ends_on]"
    end
    assert_select "#payout_exports"
  end

  test "a valid range is requested and the job is enqueued" do
    assert_enqueued_with(job: PayoutExportJob) do
      post seller_payout_exports_path(@seller),
           params: { payout_export: { starts_on: "2026-09-01", ends_on: "2026-09-30" } }
    end

    assert_redirected_to seller_payout_exports_path(@seller)
    assert_equal "Export requested.", flash[:notice]
    assert_equal @seller, PayoutExport.last.seller
  end

  test "an invalid range renders the page with 422" do
    assert_no_enqueued_jobs do
      post seller_payout_exports_path(@seller),
           params: { payout_export: { starts_on: "2026-09-30", ends_on: "2026-09-01" } }
    end

    assert_response :unprocessable_entity
    assert_select "form[action=?]", seller_payout_exports_path(@seller)
  end

  test "a ready export downloads as CSV" do
    export = ready_export

    get seller_payout_export_path(@seller, export)

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match "attachment", response.headers["Content-Disposition"]
    assert_equal "date,amount,state,reason", response.body.lines.first.chomp
  end

  # The page subscribes to whatever streams it likes; when the job is done,
  # one of them gets the "Download CSV" link.
  test "the seller's page gets the download link when the job is done" do
    export = PayoutExport.create!(seller: @seller, starts_on: Date.new(2026, 9, 1), ends_on: Date.new(2026, 9, 30))
    get seller_payout_exports_path(@seller)
    streams = css_select("turbo-cable-stream-source").map { Turbo.signed_stream_verifier.verified(_1["signed-stream-name"]) }
    assert streams.any?, "the export page subscribes to no Turbo Stream"

    perform_enqueued_jobs { PayoutExportJob.perform_now(export) }

    link = seller_payout_export_path(@seller, export)
    messages = streams.flat_map { |stream| broadcasts(stream) }
    assert messages.any? { |m| ActiveSupport::JSON.decode(m).include?(link) },
           "no broadcast with a link to #{link} on #{streams.inspect}"
  end

  private
    def ready_export
      export = PayoutExport.create!(seller: @seller, starts_on: Date.new(2026, 9, 1), ends_on: Date.new(2026, 9, 30))
      PayoutExportJob.perform_now(export)
      export.reload
    end
end
