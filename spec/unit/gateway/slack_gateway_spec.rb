describe Gateway::SlackGateway, :set_with_timecop do
  subject(:gateway) { described_class.new(slack_web_client:) }

  let(:slack_web_client) { instance_double(Slack::Web::Client) }
  let(:file_path) { File.join Dir.pwd, "spec/fixtures/postcodes_test.csv" }
  let(:slack_external_url_body) { { "upload_url" => "https://files.slack.com/upload/v1/Ad4FoJN1mC67CgACFF", "file_id" => "F07KB41F4P7", "ok" => true } }

  before do
    EnvironmentStub.with("SLACK_EPB_BOT_TOKEN", "12345")
    HttpStub.enable_webmock
    WebMock.stub_request(:post, slack_external_url_body["upload_url"]).to_return(status: 200, headers: {}, body: "OK - 534")
    allow(slack_web_client).to receive_messages(files_getUploadURLExternal: slack_external_url_body, files_completeUploadExternal: true)
  end

  after do
    EnvironmentStub.remove(%w[SLACK_EPB_BOT_TOKEN])
    WebMock.disable!
  end

  context "when the class in initialised" do
    it "does not raise an error" do
      expect { gateway }.not_to raise_error
    end

    describe "#upload_file" do
      before do
        gateway.upload_file(file_path:, message: "this is a test message")
      end

      it "posts to the Slack files.getUploadURLExternal with correct file" do
        expect(slack_web_client).to have_received(:files_getUploadURLExternal).with(filename: "postcodes_test.csv", length: 4330)
      end

      it "posts to the Slack files_completeUploadExternal with the correct info" do
        files = [{ id: slack_external_url_body["file_id"], title: "this is a test message" }].to_json
        expect(slack_web_client).to have_received(:files_completeUploadExternal).with(files:, channel_id: "C02LETGH0CR", initial_comment: "this is a test message")
      end
    end

    describe "#post_file" do
      before do
        gateway.post_file(url: slack_external_url_body["upload_url"], file_path:, filename: "postcodes_test.csv")
      end

      it "posts to the file the slack api" do
        expect(WebMock).to have_requested(:post, slack_external_url_body["upload_url"]).with(headers: { "Content-Type" => %r{multipart/form-data} })
      end

      context "when the upload fails" do
        it "raises an SlackMessageError error with a 200 where body: ok" do
          WebMock.stub_request(:post, slack_external_url_body["upload_url"]).to_return(status: 200, headers: {}, body: { test: false }.to_json)
          expect { gateway.post_file(url: slack_external_url_body["upload_url"], file_path:, filename: "postcodes_test.csv") }.to raise_error Boundary::SlackMessageError
        end

        it "raises a slack error message status 500" do
          WebMock.stub_request(:post, slack_external_url_body["upload_url"]).to_return(status: 500, headers: {})

          expect { gateway.post_file(url: slack_external_url_body["upload_url"], file_path:, filename: "postcodes_test.csv") }.to raise_error Boundary::SlackMessageError
        end
      end
    end
  end
end
