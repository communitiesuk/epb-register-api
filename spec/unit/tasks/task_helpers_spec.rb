describe Tasks::TaskHelpers do
  context "When the stage is production" do
    before do
      allow(ENV).to receive(:[]).and_call_original
    end

    it "raises an error with a useful message" do
      allow(ENV).to receive(:[]).with("STAGE").and_return("production")
      expect { described_class.quit_if_production }.to raise_error(
        StandardError,
      ).with_message("This task can only be run if the STAGE is test, development, integration or staging")
    end
  end

  context "When the stage is not production" do
    before do
      allow(ENV).to receive(:[]).and_call_original
    end

    it "does not raise an error" do
      other_stages = %w[test development integration staging]
      expect {
        other_stages.each do |stage|
          allow(ENV).to receive(:[]).with("STAGE").and_return(stage)
          described_class.quit_if_production
        end
      }.not_to raise_error
    end
  end
end
