require 'base64'

require 'aws-sdk-sns'
require 'httparty'
require 'json'
require 'msgpack'
require 'octokit'

require 'base64'

require File.expand_path(__dir__ + "/../lib/try_create_hook")

verifier = Aws::SNS::MessageVerifier.new

Handler = Proc.new do |req, res|
  return if !verifier.authentic? req.body

  res.status = 200
  res.body = ''

  req_body = JSON.parse(req.body)
  if req['x-amz-sns-message-type'] == 'SubscriptionConfirmation' then
    confirmURL = req_body['SubscribeURL']
    puts confirmURL
    HTTParty.get(confirmURL)
    return
  end

  params = MessagePack.unpack(Base64.decode64(req_body['Message']))

  github_api = Octokit::Client.new(access_token: ENV['GITHUB_API_ACCESS_TOKEN'])

  try_create_hook(github_api, params['repo'], params['delay'])

end