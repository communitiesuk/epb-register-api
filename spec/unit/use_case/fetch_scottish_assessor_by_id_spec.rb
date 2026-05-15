describe UseCase::FetchScottishAssessorById do
  context "when fetching an assessor" do
    subject(:use_case) { described_class.new(gateway) }

    let(:gateway) { instance_double(Gateway::AssessorsGateway) }

    let(:expected_result) do
      {
        first_name: "Test",
        middle_names: "A",
        last_name: "Tester",
        email: "test@example.com",
        address: {
          address_line1: "789 Test Street",
          address_line2: "",
          address_line3: "",
          town: "London",
          postcode: "TE1 2ST",
        },
        scheme_assessor_id: "ACME123418",
        registered_by: "test scheme",
        qualifications: {
          domestic_rd_sap: "ACTIVE",
          domestic_sap: "ACTIVE",
          non_domestic_dec: "ACTIVE",
          non_domestic_nos3: "ACTIVE",
          non_domestic_nos4: "ACTIVE",
          non_domestic_nos5: "ACTIVE",
          non_domestic_sp3: "ACTIVE",
          non_domestic_cc4: "ACTIVE",
          gda: "ACTIVE",
          scotland_rdsap: "INACTIVE",
          scotland_sap_existing_building: "INACTIVE",
          scotland_sap_new_building: "INACTIVE",
          scotland_dec_and_ar: "INACTIVE",
          scotland_nondomestic_existing_building: "INACTIVE",
          scotland_nondomestic_new_building: "INACTIVE",
          scotland_section63: "INACTIVE",
        },
      }
    end

    let(:args) do
      {
        first_name: "Test",
        middle_names: "A",
        last_name: "Tester",
        email: "test@example.com",
        address_line1: "789 Test Street",
        address_line2: "",
        address_line3: "",
        town: "London",
        postcode: "TE1 2ST",
        scheme_assessor_id: "ACME123418",
        registered_by_name: "test scheme",
        domestic_rd_sap_qualification: "ACTIVE",
        domestic_sap_qualification: "ACTIVE",
        non_domestic_dec_qualification: "ACTIVE",
        non_domestic_nos3_qualification: "ACTIVE",
        non_domestic_nos4_qualification: "ACTIVE",
        non_domestic_nos5_qualification: "ACTIVE",
        non_domestic_sp3_qualification: "ACTIVE",
        non_domestic_cc4_qualification: "ACTIVE",
        gda_qualification: "ACTIVE",
        scotland_rdsap_qualification: "INACTIVE",
        scotland_sap_existing_building_qualification: "INACTIVE",
        scotland_sap_new_building_qualification: "INACTIVE",
        scotland_dec_and_ar_qualification: "INACTIVE",
        scotland_nondomestic_existing_building_qualification: "INACTIVE",
        scotland_nondomestic_new_building_qualification: "INACTIVE",
        scotland_section63_qualification: "INACTIVE",
      }
    end

    let(:domain_object) { Domain::Assessor.new(**args) }

    before do
      allow(gateway).to receive(:fetch).with("ABC123").and_return(domain_object)
    end

    it "calls the gateway with the correct argument" do
      use_case.execute(scheme_assessor_id: "ABC123")
      expect(gateway).to have_received(:fetch).with("ABC123")
    end

    it "returns the assessor" do
      assessor = use_case.execute(scheme_assessor_id: "ABC123")
      expect(assessor).to eq(expected_result)
    end

    context "when the assessor is not found" do
      before do
        allow(gateway).to receive(:fetch).with("unfound-id").and_return(nil)
      end

      it "raises AssessorNotFoundException" do
        expect { use_case.execute(scheme_assessor_id: "unfound-id") }.to raise_error(Boundary::AssessorNotFoundException)
      end
    end
  end
end
