require "sentry-ruby"

describe Tasks::TaskHelpers do
  describe "#quit_if_production" do
    context "when the stage is production" do
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

    context "when the stage is not production" do
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

  describe "#get_last_months_methods" do
    context "when it is the first day of the month (1st Sept 2022)" do
      before do
        Timecop.freeze(2022, 9, 1, 7, 0, 0)
      end

      after do
        Timecop.return
      end

      it "returns the 1st day of previous month" do
        expect(described_class.get_last_months_dates[:start_date]).to eq "2022-08-01"
      end

      it "returns the last day of the previous month" do
        expect(described_class.get_last_months_dates[:end_date]).to eq "2022-09-01"
      end
    end
  end
end
