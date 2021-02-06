require 'aws-sdk-states'
require 'msgpack'
require 'octokit'

require 'base64'

def try_create_hook(github_api, repo_name, wait)
  begin
    github_api.create_hook(repo_name,
      "web",
      {
        url: ENV['GITHUB_WEBHOOK_ENDPOINT'],
        secret: ENV['GITHUB_WEBHOOK_SECRET'],
        content_type: 'json'
      },
      {
        events: [
          'pull_request',
          'issue_comment',
          'pull_request_review_comment'
        ],
        active: true
      }
    )
    puts "#{repo_name}: done!"
  rescue Octokit::NotFound
    if wait > 60000 then # we waited for more than a minute (60000 < 100 + 200 + 400 + 800 + 1600 + 3200 + 6400 + 12800 + 25600 + 51200)
      puts "after waiting for more than a minute, we still do not have a working repo. panic!"
      return
    end
    puts "Github did not create the fork yet. Trying again in #{wait}ms..."
    send_retry_message(repo_name, wait * 2)
  end
end

def send_retry_message(repo_name, wait)
  aws_credentials = Aws::AssumeRoleCredentials.new(
    role_session_name: 'anonydog-website',
    role_arn: ENV['STATE_MACHINE_ROLE_ARN'],
    client: Aws::STS::Client.new(
      region: 'us-west-2',
      credentials: Aws::Credentials.new(
        ENV['STATE_MACHINE_ACCESS_KEY'],
        ENV['STATE_MACHINE_SECRET_KEY'],
      ),
    ),
  )
  aws_client = Aws::States::Client.new(
    region: 'us-west-2',
    credentials: aws_credentials,
  )
  aws_client.start_execution(
    state_machine_arn: ENV['STATE_MACHINE_ARN'],
    input: JSON.encode({
      delay_seconds: wait / 1000,
      message: Base64.encode({repo: repo_name, delay: wait}.to_msgpack),
    })
  )
end