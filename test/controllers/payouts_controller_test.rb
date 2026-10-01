require "test_helper"

class PayoutsControllerTest < ActionDispatch::IntegrationTest
  test "shows the queue" do
    get payouts_path
    assert_response :success
    assert_select "#payout_requests"
    assert_match "Clara Wolf", response.body
  end
end
