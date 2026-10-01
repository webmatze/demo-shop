# frozen_string_literal: true

# The request as one paragraph of text -- exactly what the model gets to see,
# and exactly what the generator writes. One method for both, or the
# measurement does not apply to what we ask in production.
module PayoutDescription
  module_function

  def call(r)
    [
      "Seller account opened #{r["account_age_days"]} days ago.",
      "#{r["orders"]} completed orders, #{money(r["lifetime_sales"])} lifetime sales,",
      "last order #{r["days_since_last_order"]} days ago.",
      bank(r),
      location(r),
      "Payout amount: #{money(r["amount"])}."
    ].join(" ")
  end

  def money(amount) = "#{format('%d', amount)} EUR"

  def bank(r)
    h = r["iban_changed_hours_ago"]
    return "Bank account unchanged since the account was opened." if h.nil?

    h < 48 ? "Bank account was changed #{h} hours ago." : "Bank account was changed #{h / 24} days ago."
  end

  def location(r)
    same = r["login_country"] == r["request_country"]
    proxy = r["via_proxy"] ? " through an anonymising proxy" : ""
    if same && !r["via_proxy"]
      "Login and payout request both from #{r["login_country"]}."
    else
      "Login from #{r["login_country"]}, payout requested from #{r["request_country"]}#{proxy}."
    end
  end
end
