require "test_helper"

class LayaClientTest < ActiveSupport::TestCase
  test "an unreachable model is Unavailable, not a crash" do
    client = LayaClient.new(url: URI("http://127.0.0.1:1/v1/systemone"), timeout: 1)
    assert_raises(LayaClient::Unavailable) { client.legitimacy("some payout request") }
  end
end
