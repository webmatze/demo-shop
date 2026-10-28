# AGENTS.md — demo-shop

Rails 8.1, Ruby 3.3.6, SQLite, Minitest, Hotwire. No Node.

## Commands

    bin/rails db:prepare     # once per worktree
    bin/rails test           # must be green before you say "done"
    bin/rails test <file>    # one file while you work

## Conventions

- Plain Rails: fat models, thin controllers, no service objects unless the
  brief asks for one.
- Business rules live in the model and have a model test.
- Controllers respond with Turbo Streams where a page updates in place;
  keep a plain HTML fallback.
- Views use the existing classes in application.css (`card`, `actions`,
  `button`, `notice`). No new colors.
- Money is `decimal(8,2)`. Never floats.

## Working rules

- Stay inside the scope of your brief.
- One commit per task, message in English, imperative.
- Never push, never merge, never edit `db/schema.rb` by hand.
- "Done" means: you ran `bin/rails test`, it is green, and you paste the
  last three lines of its output in your report.
