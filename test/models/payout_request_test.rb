require "test_helper"

class PayoutRequestTest < ActiveSupport::TestCase
  test "describes itself with the same sentences as the generator" do
    text = payout_requests(:clean).to_state
    assert_includes text, "Seller account opened 1274 days ago."
    assert_includes text, "356 completed orders"
    assert_includes text, "Payout amount: 607 EUR."
  end

  test "knows only the four states" do
    request = payout_requests(:clean)
    assert request.valid?
    request.state = "paid"
    assert_not request.valid?
  end

  test "decide! records probability and reason" do
    request = payout_requests(:clean)
    request.decide!("review", probability: 0.78, reason: "not sure")
    assert_equal ["review", "not sure"], [request.state, request.reason]
    assert_in_delta 0.78, request.probability, 0.001
  end
end
