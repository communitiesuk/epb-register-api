require "http"

module Worker
  class SlackNotification
    include Sidekiq::Worker

    def perform(text, url = nil)
      @webhook_url = ENV["EPB_TEAM_SLACK_URL"]

      if @webhook_url.present?
        message = url.present? ? Helper::SlackHelper.hyperlink(text, url) : text
        Helper::SlackHelper.post_to_slack text: message, webhook_url: @webhook_url
      end
    end
  end
end
