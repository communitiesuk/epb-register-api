describe UseCase::FindAssessmentsByAssessmentId do
  subject(:use_case) { described_class.new }

  let(:assessments_search_gateway) { instance_double(Gateway::AssessmentsSearchGateway) }
  let(:first_assessment) do
    Domain::AssessmentSearchResult.new(
      type_of_assessment: "RdSAP",
      assessment_id: "0000-0000-0000-0000-0000",
      current_energy_efficiency_rating: 50,
      opt_out: false,
      postcode: "A0 0AA",
      date_of_expiry: Time.new(2030, 5, 3).to_date,
      date_registered: Time.new(2020, 5, 4).to_date,
      address_id: "UPRN-000000000123",
      address_line1: "1 Some Street",
      address_line2: "",
      address_line3: "",
      address_line4: "",
      town: "Whitbury",
      date_of_assessment: Time.new(2020, 5, 4).to_date,
      created_at: Time.utc(2030, 5, 4, 9, 0, 0),
    )
  end
  let(:second_assessment) do
    Domain::AssessmentSearchResult.new(
      type_of_assessment: "RdSAP",
      assessment_id: "0000-0000-0000-0000-0001",
      current_energy_efficiency_rating: 50,
      opt_out: false,
      postcode: "A0 0AA",
      date_of_expiry: Time.new(2030, 5, 3).to_date,
      date_registered: Time.new(2020, 5, 4).to_date,
      address_id: "UPRN-000000000123",
      address_line1: "1 Some Street",
      address_line2: "",
      address_line3: "",
      address_line4: "",
      town: "Whitbury",
      date_of_assessment: Time.new(2020, 5, 4).to_date,
      created_at: Time.utc(2030, 5, 4, 10, 0, 0),
      cancelled_at: Time.utc(2030, 6, 4, 10, 0, 0),
    )
  end

  let(:expected_data) do
    { data: [
        { address_id: "UPRN-000000000123",
          address_line1: "1 Some Street",
          address_line2: "",
          address_line3: "",
          address_line4: "",
          assessment_id: "0000-0000-0000-0000-0000",
          created_at: "2030-05-04T09:00:00Z",
          current_energy_efficiency_band: "e",
          current_energy_efficiency_rating: 50,
          date_of_assessment: "2020-05-04",
          date_of_expiry: "2030-05-03",
          date_of_registration: "2020-05-04",
          opt_out: false,
          postcode: "A0 0AA",
          status: "ENTERED",
          town: "Whitbury",
          type_of_assessment: "RdSAP" },
      ],
      search_query: "0000-0000-0000-0000-0000" }
  end

  before do
    allow(Gateway::AssessmentsSearchGateway).to receive(:new).and_return(assessments_search_gateway)
    allow(assessments_search_gateway).to receive(:search_by_assessment_id).with("0000-0000-0000-0000-0000", { restrictive: false }).and_return([first_assessment])
    allow(assessments_search_gateway).to receive(:search_by_assessment_id).with("0000-0000-0000-0000-0001", { restrictive: false }).and_return([second_assessment])
  end

  describe ".execute" do
    it "returns the expected data" do
      expect(use_case.execute("0000-0000-0000-0000-0000")).to eq(expected_data)
    end

    it "returns cancelled certificates" do
      expectation = { data: [
                        { address_id: "UPRN-000000000123",
                          address_line1: "1 Some Street",
                          address_line2: "",
                          address_line3: "",
                          address_line4: "",
                          assessment_id: "0000-0000-0000-0000-0001",
                          created_at: "2030-05-04T10:00:00Z",
                          current_energy_efficiency_band: "e",
                          current_energy_efficiency_rating: 50,
                          date_of_assessment: "2020-05-04",
                          date_of_expiry: "2030-05-03",
                          date_of_registration: "2020-05-04",
                          opt_out: false,
                          postcode: "A0 0AA",
                          status: "CANCELLED",
                          town: "Whitbury",
                          type_of_assessment: "RdSAP" },
                      ],
                      search_query: "0000-0000-0000-0000-0001" }
      expect(use_case.execute("0000-0000-0000-0000-0001")).to eq(expectation)
    end
  end
end
