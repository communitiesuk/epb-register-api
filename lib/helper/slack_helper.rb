module Helper
  class SlackHelper
    def self.hyperlink(text, url)
      "<#{url}|#{text}>"
    end

    def self.post_to_slack(text:, webhook_url:)
      if ENV["STAGE"] == "production"
        slack_message = text
        slack_channel = "#team-epb"
      else
        slack_message = "[#{ENV['STAGE']}] #{text}"
        slack_channel = "#team-epb-pre-production"
      end

      payload = {
        username: "Energy Performance of Buildings",
        channel: slack_channel,
        text: slack_message,
        mrkdwn: true,
      }

      response = HTTP.post(webhook_url, body: payload.to_json)

      unless response.status.success?
        raise Boundary::SlackMessageError, "Slack error: #{response.body}"
      end
    end
  end
end
