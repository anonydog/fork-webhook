require 'aws-sdk-sns'
require 'httparty'
require 'json'

verifier = Aws::SNS::MessageVerifier.new

Handler = Proc.new do |req, res|
  return if !verifier.authentic? req.body

  if req['x-amz-sns-message-type'] == 'SubscriptionConfirmation' then
    req_body = JSON.parse(req.body)
    confirmURL = req_body['SubscribeURL']
    HTTParty.get confirmURL
  end

  res.status = 204
end