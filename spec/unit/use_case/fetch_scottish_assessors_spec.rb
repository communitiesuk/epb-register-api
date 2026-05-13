describe UseCase::FetchScottishAssessors do
  context "when fetching assessors by date" do
    subject(:use_case) { described_class.new(gateway) }

    let(:gateway) do
      instance_double(Gateway::AssessorsGateway)
    end
    let(:args) do
      { start_date: "2025-10-20", end_date: "2025-10-30", current_page: 1 }
    end

    let(:data) do
      [expected_result,
       expected_result[:forenames] = "someone else"]
    end

    let(:expected_result) do
      {
        first_name: "Someone",
        last_name: "Person",
        scheme_assessor_id: "ACME123423",
        qualifications: {
          domestic_rd_sap: "INACTIVE",
          domestic_sap: "INACTIVE",
          non_domestic_dec: "INACTIVE",
          non_domestic_nos3: "INACTIVE",
          non_domestic_nos4: "INACTIVE",
          non_domestic_nos5: "INACTIVE",
          non_domestic_sp3: "INACTIVE",
          non_domestic_cc4: "INACTIVE",
          gda: "INACTIVE",
          scotland_rdsap: "ACTIVE",
          scotland_sap_existing_building: "ACTIVE",
          scotland_sap_new_building: "ACTIVE",
          scotland_dec_and_ar: "ACTIVE",
          scotland_nondomestic_existing_building: "ACTIVE",
          scotland_nondomestic_new_building: "ACTIVE",
          scotland_section63: "ACTIVE",
        },

      }
    end

    before do
      allow(gateway).to receive(:search_by_date).and_return(data)
    end

    it "passed the args to the gateway" do
      use_case.execute(**args)
      expect(gateway).to have_received(:search_by_date).with(start_date: "2025-10-20", end_date: "2025-10-30", current_page: 1, limit: 5000).once
    end

    it "returns assessor data from the gateway" do
      results = use_case.execute(**args)[:new_assessors]
      expect(results.length).to eq 2
      expect(results.first).to be_a Hash
    end
  end
end
