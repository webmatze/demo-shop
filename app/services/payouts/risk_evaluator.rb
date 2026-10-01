# frozen_string_literal: true

module Payouts
  # Decides a payout request.
  class RiskEvaluator
    # Both thresholds come from script/cost_table.rb -- read off, not guessed.
    PAY_OUT = 0.85
    BLOCK = 0.65

    def initialize(request, model: LayaClient.new)
      @request = request
      @model = model
    end

    def call
      p = @model.legitimacy(@request.to_state)
      if p >= PAY_OUT
        @request.decide!("approved", probability: p, reason: "clearly consistent with the account")
      elsif p <= BLOCK
        @request.decide!("blocked", probability: p, reason: "looks like a takeover, security notified")
      else
        @request.decide!("review", probability: p, reason: "not sure enough to decide alone")
      end
    rescue LayaClient::Unavailable => e
      # A model that says nothing is not a fraud signal.
      @request.decide!("review", probability: nil, reason: "model unavailable: #{e.message}")
    end
  end
end
