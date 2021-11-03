RSpec.describe Worker::SlackNotification do
  describe "#perform" do
    before do
      WebMock.enable!
      allow(ENV).to receive(:[])
    end

    after { WebMock.disable! }

    it "sends a Slack notification to this webhook if the URL is set" do
      allow(ENV).to receive(:[]).with("EPB_TEAM_SLACK_URL").and_return("https://example.com/webhook")

      slack_request = WebMock.stub_request(:post, "https://example.com/webhook")
        .to_return(status: 200, headers: {})

      invoke_worker
      expect(slack_request).to have_been_made
    end

    it "does not send a Slack notification if EPB_TEAM_SLACK_URL is empty" do
      allow(ENV).to receive(:[]).with("EPB_TEAM_SLACK_URL").and_return(nil)

      slack_request = stub_request(:post, "https://example.com/webhook")
        .to_return(status: 200, headers: {})

      invoke_worker
      expect(slack_request).not_to have_been_made
    end

    it "raises an error if Slack responds with one" do
      allow(ENV).to receive(:[]).with("EPB_TEAM_SLACK_URL").and_return("https://example.com/webhook")

      stub_request(:post, "https://example.com/webhook")
        .to_return(status: 400, headers: {})

      expect { invoke_worker }.to raise_error(Worker::SlackNotification::SlackMessageError)
    end

    it "includes a link if given" do
      allow(ENV).to receive(:[]).with("STAGE").and_return("TEST")
      allow(ENV).to receive(:[]).with("EPB_TEAM_SLACK_URL").and_return("https://example.com/webhook")

      slack_request = stub_request(:post, "https://example.com/webhook")
        .to_return(status: 200, headers: {})

      invoke_worker
      expect(slack_request.with(body: /\[TEST\] \\u003/)).to have_been_made
    end

    it "does not include a link if none given" do
      allow(ENV).to receive(:[]).with("STAGE").and_return("TEST")
      allow(ENV).to receive(:[]).with("EPB_TEAM_SLACK_URL").and_return("https://example.com/webhook")

      slack_request = stub_request(:post, "https://example.com/webhook")
        .to_return(status: 200, headers: {})

      described_class.new.perform("example text")
      expect(slack_request.with(body: /\[TEST\] example text/)).to have_been_made
    end
  end

  def invoke_worker
    described_class.new.perform("example text", "https://example.com/stats")
  end
end
