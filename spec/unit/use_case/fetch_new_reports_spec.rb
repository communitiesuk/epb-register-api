describe UseCase::FetchNewReports do
  context "when fetching a list of rrns" do
    subject(:use_case) { described_class.new(new_reports_gateway) }

    let(:new_reports_gateway) do
      instance_double(Gateway::NewReportsGateway)
    end

    let(:data) do
      %w[0000-0000-0000-0000-0001 0000-0000-0000-0000-0002 0000-0000-0000-0000-0003]
    end

    before do
      allow(new_reports_gateway).to receive(:fetch).and_return(data)
    end

    describe "#execute" do
      it "fetches an rrn object containing an array of rrns" do
        expect(use_case.execute(start_date: "2010-01-01", end_date: "2010-02-01", current_page: 1)).to eq({ rrns: data })
      end
    end
  end
end
