require 'octokit'
require File.expand_path(__dir__ + "/try_create_hook")

def create_fork(user, repo)
  github_api = Octokit::Client.new(access_token: ENV['GITHUB_API_ACCESS_TOKEN'])
  forked_repo = github_api.fork(:owner => user, :repo => repo)
  try_create_hook(github_api, forked_repo.full_name, 100)
end