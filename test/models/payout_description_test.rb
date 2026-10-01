require "test_helper"

# The paragraph the model reads is the contract between measurement and
# production. Change it and the measured thresholds no longer apply.
class PayoutDescriptionTest < ActiveSupport::TestCase
  BASE = {
    "account_age_days" => 1274, "orders" => 356, "lifetime_sales" => 73692,
    "days_since_last_order" => 1, "iban_changed_hours_ago" => nil,
    "login_country" => "Germany", "request_country" => "Germany",
    "via_proxy" => false, "amount" => 607
  }.freeze

  test "unchanged bank and same country" do
    text = PayoutDescription.call(BASE)
    assert_includes text, "Bank account unchanged since the account was opened."
    assert_includes text, "Login and payout request both from Germany."
    assert_includes text, "Payout amount: 607 EUR."
  end

  test "a fresh bank change in hours, an older one in days" do
    assert_includes PayoutDescription.call(BASE.merge("iban_changed_hours_ago" => 6)),
                    "Bank account was changed 6 hours ago."
    assert_includes PayoutDescription.call(BASE.merge("iban_changed_hours_ago" => 96)),
                    "Bank account was changed 4 days ago."
  end

  test "proxy and country change show up in the text" do
    text = PayoutDescription.call(BASE.merge("request_country" => "Brazil", "via_proxy" => true))
    assert_includes text, "payout requested from Brazil through an anonymising proxy"
  end
end
