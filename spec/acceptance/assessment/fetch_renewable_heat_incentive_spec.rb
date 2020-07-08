# frozen_string_literal: true

describe "Acceptance::Assessment::FetchRenewableHeatIncentive" do
  include RSpecRegisterApiServiceMixin

  let(:valid_sap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/sap.xml"
  end

  context "security" do
    it "rejects a request that is not authenticated" do
      fetch_renewable_heat_incentive "123", [401], false
    end

    it "rejects a request with the wrong scopes" do
      fetch_renewable_heat_incentive "124", [403], true, {}, %w[wrong:scope]
    end
  end

  context "when a domestic assessment doesnt exist" do
    let(:response) do
      JSON.parse fetch_renewable_heat_incentive("DOESNT-EXIST", [404]).body,
                 symbolize_names: true
    end

    it "returns status 404 for a get" do
      fetch_renewable_heat_incentive "DOESNT-EXIST", [404]
    end

    it "returns an error message structure" do
      expect(response).to eq(
        { errors: [{ code: "NOT_FOUND", title: "Assessment not found" }] },
      )
    end
  end

  context "when a domestic assessment has been cancelled" do
    let(:fetch_assessor_stub) { AssessorStub.new }

    let(:valid_rdsap_xml) do
      File.read File.join Dir.pwd, "spec/fixtures/samples/rdsap.xml"
    end

    before do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(domesticRdSap: "ACTIVE"),
      )

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      update_assessment_status(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_status_body: { "status": "CANCELLED" },
        accepted_responses: [200],
        auth_data: { scheme_ids: [scheme_id] },
      )
    end

    it "returns status 410 for a get" do
      fetch_renewable_heat_incentive "0000-0000-0000-0000-0000", [410]
    end

    it "returns an error message structure" do
      response_body =
        JSON.parse fetch_renewable_heat_incentive(
          "0000-0000-0000-0000-0000",
          [410],
        ).body,
                   symbolize_names: true
      expect(response_body).to eq(
        { errors: [{ code: "GONE", title: "Assessment not for issue" }] },
      )
    end
  end

  context "when fetching a domestic assessment" do
    let(:scheme_id) { add_scheme_and_get_id }
    let(:response) do
      fetch_renewable_heat_incentive("0000-0000-0000-0000-0000")
    end

    before do
      add_assessor scheme_id,
                   "SPEC000000",
                   AssessorStub.new.fetch_request_body(domesticSap: "ACTIVE")
    end

    it "returns status 200" do
      lodge_assessment assessment_body: valid_sap_xml,
                       accepted_responses: [201],
                       auth_data: { scheme_ids: [scheme_id] },
                       schema_name: "SAP-Schema-18.0.0"

      expect(response.status).to eq(200)
    end

    context "with property summary descriptions" do
      let(:assessment) { Nokogiri.XML valid_sap_xml }

      let(:secondary_heating) do
        assessment.at("Secondary-Heating/Energy-Efficiency-Rating")
      end

      let(:secondary_heating_description) do
        Nokogiri::XML::Node.new "Description", assessment
      end

      let(:hot_water) { assessment.at("Hot-Water/Energy-Efficiency-Rating") }

      let(:hot_water_description) do
        Nokogiri::XML::Node.new "Description", assessment
      end

      let(:main_heating) do
        assessment.at("Main-Heating/Energy-Efficiency-Rating")
      end

      let(:main_heating_description) do
        Nokogiri::XML::Node.new "Description", assessment
      end

      let(:response) do
        JSON.parse fetch_renewable_heat_incentive("0000-0000-0000-0000-0000")
                     .body,
                   symbolize_names: true
      end

      before do
        main_heating_description.content = "Gas-fired central heating"
        main_heating.add_next_sibling main_heating_description

        secondary_heating_description.content = "Electric bar heater"
        secondary_heating.add_next_sibling secondary_heating_description

        hot_water_description.content = "Electrical immersion heater"
        hot_water.add_next_sibling hot_water_description

        lodge_assessment assessment_body: assessment.to_xml,
                         accepted_responses: [201],
                         schema_name: "SAP-Schema-18.0.0",
                         auth_data: { scheme_ids: [scheme_id] }
      end

      it "returns the assessment details" do
        expect(response[:data][:assessment]).to eq(
          epcRrn: "0000-0000-0000-0000-0000",
          assessorName: "Someone Muddle Person",
          reportType: "SAP",
          inspectionDate: "2006-05-04",
          lodgementDate: "2006-05-04",
          dwellingType: "Dwelling-Type0",
          postcode: "A0 0AA",
          propertyAgeBand: "K",
          tenure: "Owner-occupied",
          totalFloorArea: 10.0,
          cavityWallInsulation: true,
          loftInsulation: true,
          spaceHeating: "Gas-fired central heating",
          waterHeating: "Electrical immersion heater",
          secondaryHeating: "Electric bar heater",
          energyEfficiency: {
            currentRating: 50,
            currentBand: "e",
            potentialRating: 50,
            potentialBand: "e",
          },
        )
      end
    end
  end
end
