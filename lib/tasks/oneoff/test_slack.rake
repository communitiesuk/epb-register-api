namespace :oneoff do
  task :test_slack do
    text = "Hi Marc, am testng slack ruby gem"
    Helper::SlackHelper.new.post_to_slack(text:)
  end
end
