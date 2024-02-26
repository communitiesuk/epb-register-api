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

      uri = URI(webhook_url)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      header = { 'Content-Type': "text/json" }

      request = Net::HTTP::Post.new(uri.path, header)
      request.body = payload.to_json

      response = https.request(request)

      case response
      when Net::HTTPSuccess
        response
      when Net::HTTPRedirection
        response
      else
        raise Boundary::SlackMessageError, "Slack error: #{response.body}"
      end
    end
  end
end
