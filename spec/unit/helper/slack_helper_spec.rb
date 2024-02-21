describe Helper::SlackHelper do
  let(:helper) { described_class }

  context "when initializes slack helper with no ENV" do
    it "raises an error" do
      expect { described_class.new }.to raise_error Boundary::SlackMessageError, "Missing ENV[SLACK_API_TOKEN]!"
    end
  end

  context "when calling the slack helper to post to the pre production channel" do

    let(:text){
      "This is a slack message to team epb."
    }

    before  do
      EnvironmentStub.with("SLACK_EPB_BOT_TOKEN", "my-ebb-bearer-token" )
      described_class.new
      WebMock.enable!
      WebMock.stub_request(:post, "https://slack.com/api/auth.test").to_return(status: 200, body: "", headers: {})
      WebMock.stub_request(:post, "https://slack.com/api/chat.postMessage").to_return(status: 200, body: "", headers: {})
    end

    after do
      WebMock.disable!
      EnvironmentStub.remove %w[SLACK_EPB_BOT_TOKEN]
    end

    it "does nto raise an error" do
      expect { described_class.new }.not_to raise_error
    end

    it "has the request authenticated by slack passing the correct bearer token" do
      described_class.new.post_to_slack(text:)
      expect(WebMock).to have_requested(:post, "https://slack.com/api/auth.test").with(headers: {'Accept' => 'application/json; charset=utf-8',
                                                                             'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                                                                             'Authorization' => 'Bearer my-ebb-bearer-token',
                                                                             'Content-Length' => '0',
                                                                             'User-Agent' => 'Slack Ruby Client/2.3.0' })
    end


    it "send a post request to slack" do
      described_class.new.post_to_slack(text:)

      expect(WebMock).to have_requested(
                          :post,
                          "https://slack.com/api/chat.postMessage").with(body: {"as_user" => "true", "channel" => "#team-epb-pre-production", "text" => "[test] This is a slack message to team epb."})
    end
  end

end
