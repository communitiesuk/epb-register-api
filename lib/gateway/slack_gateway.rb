require "slack"

module Gateway
  class SlackGateway
    def initialize(slack_web_client:)
      Slack.configure do |config|
        config.token = ENV["SLACK_EPB_BOT_TOKEN"]
      end
      @client = slack_web_client || Slack::Web::Client.new
    end

    def upload_file(file_path:, message:)
      filename = File.basename(file_path)
      channel_id = ENV["STAGE"] == "production" ? "CJ9DGBZ6C" : "C02LETGH0CR"
      upload_response = @client.files_getUploadURLExternal(filename:, length: File.size(file_path))
      post_file(url: upload_response["upload_url"], file_path:, filename:)
      files = [{ id: upload_response["file_id"], title: message }].to_json
      @client.files_completeUploadExternal(files:, channel_id:, initial_comment: message)
    rescue Boundary::SlackMessageError => e
      raise e
    end

    def post_file(url:, file_path:, filename:)
      uri = URI(url)
      req = Net::HTTP::Post.new(uri)

      form = [
        [
          "file",
          File.open(file_path),
        ],
        [
          "filename",
          filename,
        ],
      ]
      req.set_form(
        form,
        "multipart/form-data",
      )

      req_options = {
        use_ssl: uri.scheme == "https",
      }
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(req)
      end

      unless response.is_a?(Net::HTTPSuccess) && response.body.include?("OK")
        raise Boundary::SlackMessageError, "Slack error: #{response.body}"
      end
    end
  end
end
