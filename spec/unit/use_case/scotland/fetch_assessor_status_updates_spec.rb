describe UseCase::Scotland::FetchAssessorStatusUpdates do
  context "when fetching a list of events" do
    subject(:use_case) { described_class.new(assessor_status_events_gateway) }

    let(:assessor_status_events_gateway) do
      instance_double(Gateway::AssessorsStatusEventsGateway)
    end

    let(:data) do
      [{
        first_name: "April",
        last_name: "Mason",
        scheme_assessor_id: "ABC123",
        qualification_change: { new_status: "ACTIVE",
                                previous_status: "INACTIVE",
                                qualification_type: "scotland_rdsap" },
      },
       {
         first_name: "June",
         last_name: "Julian",
         scheme_assessor_id: "ABC456",
         qualification_change: { new_status: "ACTIVE",
                                 previous_status: "STRUCKOFF",
                                 qualification_type: "scotland_section63" },
       }]
    end

    before do
      allow(assessor_status_events_gateway).to receive(:get_scottish_assessor_events).and_return(data)
    end

    describe "#execute" do
      it "fetches an array of assessor status events" do
        expect(use_case.execute(start_date: "2013-01-01", end_date: "2013-01-05", current_page: 1)).to eq({ assessorStatusEvents: data })
      end
    end
  end
end
