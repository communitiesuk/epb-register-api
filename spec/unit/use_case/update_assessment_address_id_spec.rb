describe UseCase::UpdateAssessmentAddressId do
  subject(:use_case) do
    described_class.new(
      address_base_gateway: address_base_gateway,
      assessments_address_id_gateway: assessments_address_id_gateway,
      assessments_search_gateway: assessments_search_gateway,
      assessments_gateway: assessments_gateway,
      event_broadcaster: Events::Broadcaster.new,
    )
  end

  let(:address_base_gateway) { instance_double(Gateway::AddressBaseSearchGateway) }
  let(:assessments_address_id_gateway) { instance_double(Gateway::AssessmentsAddressIdGateway) }
  let(:assessments_search_gateway) { instance_double(Gateway::AssessmentsSearchGateway) }
  let(:assessments_gateway) { instance_spy(Gateway::AssessmentsGateway) }

  before do
    allow(assessments_gateway).to receive(:get_linked_assessment_id).and_return(nil)

    allow(assessments_search_gateway).to receive(:search_by_assessment_id).and_return([Domain::AssessmentSearchResult.new({ assessment_id: "2000-0000-0000-0000-0001" })])

    allow(address_base_gateway).to receive(:check_uprn_exists).and_return(true)

    allow(assessments_address_id_gateway).to receive(:fetch)
    allow(assessments_address_id_gateway).to receive(:update_assessments_address_id_mapping)
  end

  describe ".execute" do
    it "raises an exception for an invalid address_id format" do
      expect { use_case.execute("2000-0000-0000-0000-0001", "00000000001") }.to raise_error(
        described_class::InvalidAddressIdFormat, "AddressId has to begin with UPRN- or RRN-"
      )
    end

    it "calls AssessmentsAddressIdGateway to update the assessment data in the assessments_address_id table" do
      use_case.execute("2000-0000-0000-0000-0001", "UPRN-00000000001")

      expect(assessments_address_id_gateway).to have_received(:update_assessments_address_id_mapping).with(%w[2000-0000-0000-0000-0001], "UPRN-00000000001")
    end

    describe "event examples" do
      around do |test|
        Events::Broadcaster.enable!
        test.run
        Events::Broadcaster.disable!
      end

      it "broadcasts an assessment_address_id_updated event" do
        expect { use_case.execute("2000-0000-0000-0000-0001", "UPRN-00000000002") }.to broadcast(
          :assessment_address_id_updated,
          assessment_id: "2000-0000-0000-0000-0001",
          new_address_id: "UPRN-00000000002",
        )
      end
    end
  end
end
