
require 'slack-ruby-client'

module Helper
  class SlackHelper
    def initialize
      Slack.configure do |config|
        config.token = ENV["SLACK_EPB_BOT_TOKEN"]
        raise Boundary::SlackMessageError, "Missing ENV[SLACK_API_TOKEN]!" unless config.token
      end
    end

    def hyperlink(text, url)
      "<#{url}|#{text}>"
    end

    def post_to_slack(text:)
      if ENV["STAGE"] == "production"
        channel = "#team-epb"
      else
        text = "[#{ENV['STAGE']}] #{text}"
        channel = "#team-epb-pre-production"
      end

      client = Slack::Web::Client.new
      client.auth_test
      client.chat_postMessage(channel:, text:, as_user: true)
    end
  end
end
