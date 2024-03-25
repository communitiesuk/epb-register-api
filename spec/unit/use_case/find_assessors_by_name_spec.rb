describe UseCase::FindAssessorsByName do
  subject(:use_case) { described_class.new(assessor_gateway:) }

  context "when there are more than 20 assessors of the same name" do
    let(:assessor_gateway) do
      instance_double(Gateway::AssessorsGateway)
    end

    let(:assessor_data) do
      { first_name: "Someone",
        last_name: "Person",
        registered_by: { name: "test scheme", scheme_id: 1 },
        scheme_assessor_id: "ACME123411",
        contact_details: { email: "person@person.com", telephone_number: "010199991010101" },
        search_results_comparison_postcode: "",
        address: {},
        company_details: {},
        qualifications: { domestic_sap: "ACTIVE",
                          domestic_rd_sap: "ACTIVE",
                          non_domestic_sp3: "ACTIVE",
                          non_domestic_cc4: "ACTIVE",
                          non_domestic_dec: "ACTIVE",
                          non_domestic_nos3: "ACTIVE",
                          non_domestic_nos4: "ACTIVE",
                          non_domestic_nos5: "ACTIVE",
                          gda: "ACTIVE" },
        middle_names: "Muddle" }
    end

    before do
      data = []
      25.times do
        data << assessor_data
      end
      allow(assessor_gateway).to receive(:search_by).and_return(data)
    end

    it "returns more than 20 rows" do
      expect(use_case.execute("Someone Person")[:data].length).to eq(25)
    end
  end
end
