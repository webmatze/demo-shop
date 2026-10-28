# Brief: payout export

Sellers can request a CSV export of their payout requests for a date
range. A form object validates the range, a Solid Queue job builds the
CSV, and a Turbo Stream tells the seller when the download is ready.
The notice goes to the seller who asked, and to nobody else.

## Contract

    form = PayoutExportForm.new(seller: seller, starts_on: "2026-09-01", ends_on: "2026-09-30")
    form.save    # => true, creates form.export (a PayoutExport) and enqueues PayoutExportJob
    form.save    # => false when a date is missing or ends_on is before starts_on;
                 #    errors on :starts_on / :ends_on, nothing created, nothing enqueued

    PayoutExportJob.perform_now(export)
    export.ready?  # => true
    export.csv     # => "date,amount,state,reason\n2026-09-03,607,approved,...\n"

PayoutExport: `seller`, `starts_on`, `ends_on` (dates). The CSV has one
row per payout request of that seller created in the range, both days
included, oldest first. `date` is ISO 8601, `amount` as stored.

## Pages

- `GET /sellers/:seller_id/payout_exports` (`seller_payout_exports_path`):
  the seller's name, a form with date fields `payout_export[starts_on]`
  and `payout_export[ends_on]`, and the seller's exports in
  `#payout_exports`, newest first.
- `POST` to the same path: valid -> redirect back with the notice
  "Export requested."; invalid -> the page again with the errors, 422.
- `GET /sellers/:seller_id/payout_exports/:id`
  (`seller_payout_export_path`): the CSV as a download (`text/csv`).
- When the job is done, the page updates in place via Turbo Stream: the
  export shows a "Download CSV" link to its download path. No reload.

## Done

`bin/rails test` is green, including the tests in `test/forms/`,
`test/jobs/` and `test/controllers/` for this brief. Agents' reports
don't count: we run the suite ourselves.
