# frozen_string_literal: true

module Payouts
  # Decides a payout request.
  class RiskEvaluator
    def initialize(request, model: LayaClient.new)
      @request = request
      @model = model
    end

    # Still the old house rule: long enough on the platform, money goes out.
    def call
      if @request.seller.account_age_days >= 30
        @request.decide!("approved", probability: nil, reason: "account older than 30 days")
      else
        @request.decide!("review", probability: nil, reason: "young account")
      end
    end
  end
end
