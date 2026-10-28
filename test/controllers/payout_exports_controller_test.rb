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
    assert_select ".errors", text: /Ends on/
  end

  test "a ready export downloads as CSV" do
    export = ready_export

    get seller_payout_export_path(@seller, export)

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match "attachment", response.headers["Content-Disposition"]
    assert_equal "date,amount,state,reason", response.body.lines.first.chomp
  end

  test "a ready export is linked when the page is loaded" do
    export = ready_export

    get seller_payout_exports_path(@seller)

    assert_select "#payout_export_#{export.id} a[href=?]", seller_payout_export_path(@seller, export), text: "Download CSV"
  end

  test "a Turbo form submission renders errors as HTML" do
    post seller_payout_exports_path(@seller),
         params: { payout_export: { starts_on: "", ends_on: "" } },
         headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }

    assert_response :unprocessable_entity
    assert_equal "text/html", response.media_type
    assert_select ".errors", text: /Starts on/
    assert_select ".errors", text: /Ends on/
  end

  test "downloads are scoped to the seller and pending exports are not downloadable" do
    export = ready_export
    get seller_payout_export_path(sellers(:newcomer), export)
    assert_response :not_found

    pending = @seller.payout_exports.create!(starts_on: Date.new(2026, 9, 1), ends_on: Date.new(2026, 9, 30))
    get seller_payout_export_path(@seller, pending)
    assert_response :not_found
  end

  test "the page lists only the seller's exports newest first" do
    older = @seller.payout_exports.create!(starts_on: Date.new(2026, 8, 1), ends_on: Date.new(2026, 8, 31), created_at: 1.day.ago)
    newer = @seller.payout_exports.create!(starts_on: Date.new(2026, 9, 1), ends_on: Date.new(2026, 9, 30))
    other = sellers(:newcomer).payout_exports.create!(starts_on: Date.new(2026, 10, 1), ends_on: Date.new(2026, 10, 31))

    get seller_payout_exports_path(@seller)

    ids = css_select("#payout_exports > .card").map { _1["id"] }
    assert_equal [ "payout_export_#{newer.id}", "payout_export_#{older.id}" ], ids
    assert_not_includes ids, "payout_export_#{other.id}"
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

  test "completion replaces the export only on the requesting seller's stream" do
    export = @seller.payout_exports.create!(starts_on: Date.new(2026, 9, 1), ends_on: Date.new(2026, 9, 30))
    get seller_payout_exports_path(@seller)
    seller_stream = Turbo.signed_stream_verifier.verified(css_select("turbo-cable-stream-source").first["signed-stream-name"])
    assert_select "#payout_export_#{export.id}", text: /Export requested/

    get seller_payout_exports_path(sellers(:newcomer))
    other_stream = Turbo.signed_stream_verifier.verified(css_select("turbo-cable-stream-source").first["signed-stream-name"])
    assert_not_equal seller_stream, other_stream

    PayoutExportJob.perform_now(export)

    assert_empty broadcasts(other_stream)
    message = ActiveSupport::JSON.decode(broadcasts(seller_stream).last)
    assert_includes message, 'action="replace"'
    assert_includes message, "target=\"payout_export_#{export.id}\""
    assert_includes message, seller_payout_export_path(@seller, export)
    assert_includes message, "Download CSV"
  end

  private
    def ready_export
      export = PayoutExport.create!(seller: @seller, starts_on: Date.new(2026, 9, 1), ends_on: Date.new(2026, 9, 30))
      PayoutExportJob.perform_now(export)
      export.reload
    end
end
