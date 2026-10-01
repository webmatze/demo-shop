class EvaluatePayoutRiskJob < ApplicationJob
  queue_as :default

  retry_on LayaClient::Unavailable, wait: :polynomially_longer, attempts: 3

  def perform(request)
    Payouts::RiskEvaluator.new(request).call
  end
end
