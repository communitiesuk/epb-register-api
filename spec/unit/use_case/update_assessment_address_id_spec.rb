describe UseCase::UpdateAssessmentAddressId do
  let(:use_case) { described_class.new }
  let(:address_base_gateway) { instance_double(Gateway::AddressBaseSearchGateway) }
  let(:assessments_address_id_gateway) { instance_double(Gateway::AssessmentsAddressIdGateway) }
  let(:assessments_search_gateway) { instance_double(Gateway::AssessmentsSearchGateway) }
  let(:assessments_gateway) { instance_double(Gateway::AssessmentsGateway) }

  before do
    allow(Gateway::AssessmentsGateway).to receive(:new).and_return(assessments_gateway)
    allow(assessments_gateway).to receive(:get_linked_assessment_id).and_return(nil)

    allow(Gateway::AssessmentsSearchGateway).to receive(:new).and_return(assessments_search_gateway)
    allow(assessments_search_gateway).to receive(:search_by_assessment_id).and_return([Domain::AssessmentSearchResult.new({ assessment_id: "2000-0000-0000-0000-0001" })])

    allow(Gateway::AddressBaseSearchGateway).to receive(:new).and_return(address_base_gateway)
    allow(address_base_gateway).to receive(:check_uprn_exists).and_return(true)

    allow(Gateway::AssessmentsAddressIdGateway).to receive(:new).and_return(assessments_address_id_gateway)
    allow(assessments_address_id_gateway).to receive(:fetch)
    allow(assessments_address_id_gateway).to receive(:update_assessments_address_id_mapping)
  end

  describe ".execute" do
    it "calls AssessmentsAddressIdGateway to update the assessment data in the assessments_address_id table" do
      use_case.execute("2000-0000-0000-0000-0001", "UPRN-00000000001")

      expect(assessments_address_id_gateway).to have_received(:update_assessments_address_id_mapping).with(%w[2000-0000-0000-0000-0001], "UPRN-00000000001")
    end
  end
end
