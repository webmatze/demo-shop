# Brief: coupon codes

Customers can redeem a coupon code on an order. A code works once.
A second redemption of the same code must fail.

## Contract

    order.apply_coupon("WELCOME10")  # => true, total reduced by percent_off
    order.apply_coupon("WELCOME10")  # => false, order.errors[:coupon] set

Coupon: `code` (string, case-insensitive), `percent_off` (1..100).
An order has at most one coupon.

## Part A — Builder-A (worktree wt-a)

Model and data. Owns `db/`, `app/models/`, `test/models/`,
`test/fixtures/`. Makes `test/models/coupon_test.rb` green.

## Part B — Builder-B (worktree wt-b)

Controller and UI. Owns `app/controllers/`, `app/views/`,
`config/routes.rb`, `test/controllers/`. A form on the order page;
the total and the error message update via Turbo Stream.
`Coupon` does not exist in wt-b yet: build against the contract.
Your tests go green after Part A is merged.

## Done

Red tests first (chief), then both parts, one commit each.
The chief runs `bin/rails test` on the merged result. Agents' reports
don't count.
