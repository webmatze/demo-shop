# frozen_string_literal: true

require "net/http"
require "json"

# Asks the local decision model. No key, no third party: `laya-serve` runs
# next to the app and answers in about 200 ms.
#
# The answer carries `confidence` as well as `noul`. That is max(p, 1-p) --
# only how far the model is from 0.5. Checked against an approval threshold it
# would pay out a request the model is sure is fraud. We use `noul`.
class LayaClient
  class Unavailable < StandardError; end

  QUESTION = "Does this payout request show signs of fraud or account takeover?"
  URL = URI(ENV.fetch("LAYA_URL", "http://127.0.0.1:8000/v1/systemone"))

  def initialize(url: URL, timeout: 10)
    @url = url
    @timeout = timeout
  end

  # @return [Float] probability that the request is legitimate
  def legitimacy(state) = 1.0 - ask(state, QUESTION)

  # The raw answer to one typed question: how likely the answer is "yes".
  def ask(state, question)
    req = Net::HTTP::Post.new(@url, "Content-Type" => "application/json")
    req.body = JSON.generate(state: state, questions: { fraud: { type: "noul", instructions: question } })
    res = Net::HTTP.start(@url.host, @url.port, read_timeout: @timeout, open_timeout: 2) { |h| h.request(req) }
    noul = JSON.parse(res.body).dig("answers", "fraud", "noul")
    raise Unavailable, "no answer from the model" if noul.nil?

    noul
  rescue SystemCallError, Net::OpenTimeout, Net::ReadTimeout, JSON::ParserError => e
    raise Unavailable, e.message
  end
end
