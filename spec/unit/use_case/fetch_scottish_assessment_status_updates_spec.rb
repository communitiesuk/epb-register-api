describe UseCase::FetchScottishAssessmentStatusUpdates do
  context "when fetching a list of events" do
    subject(:use_case) { described_class.new(audit_logs_gateway) }

    let(:audit_logs_gateway) do
      instance_double(Gateway::AuditLogsGateway)
    end

    let(:data) do
      [{
        reportRrn: "0000-0000-0000-0000-0001",
        newStatus: "OPTED OUT",
        timeOfChange: Time.new(2013, 1, 2),
      },
       {
         reportRrn: "0000-0000-0000-0000-0002",
         newStatus: "CANCELLED",
         timeOfChange: Time.new(2013, 1, 3),
       }]
    end

    before do
      allow(audit_logs_gateway).to receive(:fetch_scottish_events).and_return(data)
    end

    describe "#execute" do
      it "fetches an rrn object containing an array of rrns" do
        expect(use_case.execute(start_date: "2013-01-01", end_date: "2013-01-05", current_page: 1)).to eq({ statusUpdates: data })
      end
    end
  end
end
