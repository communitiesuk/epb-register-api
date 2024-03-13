describe "fetching BUS (Boiler Upgrade Scheme) details from the API", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }
  let(:scheme_id) do
    scheme_id = add_scheme_and_get_id
    add_assessor(
      scheme_id:,
      assessor_id: "SPEC000000",
      body: fetch_assessor_stub.fetch_request_body(
        non_domestic_dec: "ACTIVE",
        non_domestic_nos3: "ACTIVE",
        domestic_rd_sap: "ACTIVE",
        domestic_sap: "ACTIVE",
      ),
    )
    scheme_id
  end

  let(:rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }
  let(:sap_xml) { Samples.xml "SAP-Schema-18.0.0" }
  let(:cepc_xml) { Samples.xml "CEPC-8.0.0", "cepc" }
  let(:dec_xml) { Samples.xml "CEPC-8.0.0", "dec" }

  let(:expected_rdsap_details) do
    {
      epcRrn: "0000-0000-0000-0000-0000",
      reportType: "RdSAP",
      expiryDate: "2030-05-03",
      cavityWallInsulationRecommended: false,
      loftInsulationRecommended: false,
      secondaryHeating: "Room heaters, electric",
      address: {
        addressLine1: "1 Some Street",
        addressLine2: "",
        addressLine3: "",
        addressLine4: "",
        town: "Whitbury",
        postcode: "A0 0AA",
      },
      dwellingType: "Mid-terrace house",
      lodgementDate: "2020-05-04",
      uprn: "000000000000",
      tenure: "Owner-occupied",
      inspectionDate: "2020-05-04",
      mainFuelType: nil,
      wallsDescription: ["Solid brick, as built, no insulation (assumed)", "Cavity wall, as built, insulated (assumed)"],
      totalFloorArea: 55,
      totalRoofArea: nil,
      currentEnergyEfficiencyRating: 50,
      hotWaterDescription: "From main system",
    }
  end

  let(:expected_sap_details) do
    {
      epcRrn: "0000-0000-0000-0000-0000",
      reportType: "SAP",
      expiryDate: "2030-05-03",
      cavityWallInsulationRecommended: false,
      loftInsulationRecommended: false,
      secondaryHeating: "Electric heater",
      address: {
        addressLine1: "1 Some Street",
        addressLine2: "Some Area",
        addressLine3: "Some County",
        addressLine4: "",
        town: "Whitbury",
        postcode: "A0 0AA",
      },
      dwellingType: "Mid-terrace house",
      lodgementDate: "2020-05-04",
      uprn: "000000000000",
      tenure: "Owner-occupied",
      inspectionDate: "2020-05-04",
      mainFuelType: nil,
      wallsDescription: ["Brick walls", "Brick walls"],
      totalFloorArea: 69,
      totalRoofArea: 0,
      currentEnergyEfficiencyRating: 50,
      hotWaterDescription: "Gas boiler",
    }
  end

  let(:expected_cepc_details) do
    {
      epcRrn: "0000-0000-0000-0000-0000",
      reportType: "CEPC",
      expiryDate: "2026-05-04",
      cavityWallInsulationRecommended: nil,
      loftInsulationRecommended: nil,
      secondaryHeating: nil,
      address: {
        addressLine1: "Some Unit",
        addressLine2: "2 Lonely Street",
        addressLine3: "Some Area",
        addressLine4: "Some County",
        town: "Whitbury",
        postcode: "A0 0AA",
      },
      dwellingType: "B1 Offices and Workshop businesses",
      lodgementDate: "2020-05-04",
      uprn: "000000000001",
      tenure: nil,
      inspectionDate: "2020-05-04",
      mainFuelType: nil,
      wallsDescription: nil,
      totalFloorArea: 0,
      totalRoofArea: nil,
      currentEnergyEfficiencyRating: 80,
      hotWaterDescription: nil,
    }
  end

  context "when getting BUS details with a RRN" do
    context "when the RRN is associated with an assessment that BUS details can be sent for" do
      before do
        lodge_assessment(
          assessment_body: rdsap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )
      end

      it "returns the matching assessment BUS details in the expected format" do
        response = JSON.parse(
          bus_details_by_rrn("0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_rdsap_details
      end
    end

    context "when the RRN is associated with an assessment that is superseded by another assessment that BUS details can be sent for" do
      let(:latest_rrn) { "0000-0000-0000-0000-0014" }

      before do
        lodge_assessment(
          assessment_body: rdsap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )

        updated_rdsap = Nokogiri::XML rdsap_xml.clone
        updated_rdsap.at("RRN").children = latest_rrn
        updated_rdsap.at("Registration-Date").children = "2031-05-04"

        lodge_assessment(
          assessment_body: updated_rdsap.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )
      end

      it "returns a 303 response with a redirect to the URL for the BUS details for the latest assessment" do
        response = bus_details_by_rrn("0000-0000-0000-0000-0000", accepted_responses: [303])
        expect(URI(response.location).request_uri).to eq "/api/bus/assessments/latest/search?rrn=#{latest_rrn}"
      end
    end

    context "when trying to fetch BUS details with an RRN for a report type that isn't supported" do
      before do
        lodge_assessment(
          assessment_body: dec_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "CEPC-8.0.0",
        )
      end

      it "returns a 400 error with information that you are looking for the wrong type of assessment" do
        response = JSON.parse(
          bus_details_by_rrn("0000-0000-0000-0000-0000", accepted_responses: [400]).body,
          symbolize_names: true,
        )
        expect(response[:errors][0][:title]).to eq "The requested assessment type is not SAP, RdSAP, or CEPC"
      end
    end

    context "when trying to fetch BUS details with an RRN for a cancelled certificate" do
      before do
        lodge_assessment(
          assessment_body: rdsap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )

        ActiveRecord::Base.connection.exec_query("UPDATE assessments SET cancelled_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0000' ", "SQL")
      end

      it "returns a 404 error" do
        response = JSON.parse(
          bus_details_by_rrn("0000-0000-0000-0000-0000", accepted_responses: [404]).body,
          symbolize_names: true,
        )
        expect(response[:errors][0][:title]).to eq "No assessment details relevant to the BUS could be found for that query"
      end
    end
  end

  context "when getting BUS details with a UPRN" do
    context "when the UPRN is associated with assessment details that can be returned for the BUS" do
      before do
        lodge_assessment(
          assessment_body: rdsap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )
      end

      it "returns the matching assessment BUS details in the expected format" do
        response = JSON.parse(
          bus_details_by_uprn("UPRN-000000000000").body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_rdsap_details
      end
    end
  end

  context "when getting BUS details with a postcode and building name or number" do
    context "when there is one matching assessment to send BUS details for" do
      before do
        lodge_assessment(
          assessment_body: rdsap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )
      end

      it "returns the matching assessment BUS details in the expected format" do
        response = JSON.parse(
          bus_details_by_address(
            postcode: "A0 0AA",
            building_name_or_number: "1",
          ).body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_rdsap_details
      end

      context "with a building name and number that includes an unexpected character" do
        it "returns the matching assessment BUS details in the expected format" do
          response = JSON.parse(
            bus_details_by_address(
              postcode: "A0 0AA",
              building_name_or_number: "1:",
            ).body,
            symbolize_names: true,
          )

          expect(response[:data]).to eq expected_rdsap_details
        end
      end

      context "when getting BUS details with a valid postcode and building name or number but is for a certificate that has been opted out" do
        before do
          opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")
        end

        it "receives an appropriate error with a 404" do
          response = JSON.parse(
            bus_details_by_address(
              postcode: "A0 0AA",
              building_name_or_number: "1:",
              accepted_responses: [404],
            ).body,
            symbolize_names: true,
          )
          expect(response[:errors][0][:title]).to eq "No assessment details relevant to the BUS could be found for that query"
        end
      end

      context "when getting BUS details with a valid postcode and building name or number but is for a certificate that has been cancelled" do
        before do
          ActiveRecord::Base.connection.exec_query("UPDATE assessments SET cancelled_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0000' ", "SQL")
        end

        it "receives an appropriate error with a 404" do
          response = JSON.parse(
            bus_details_by_address(
              postcode: "A0 0AA",
              building_name_or_number: "1:",
              accepted_responses: [404],
            ).body,
            symbolize_names: true,
          )
          expect(response[:errors][0][:title]).to eq "No assessment details relevant to the BUS could be found for that query"
        end
      end

      context "when getting BUS details with a valid postcode and building name or number but is for a certificate that has been marked as not for issue" do
        before do
          ActiveRecord::Base.connection.exec_query("UPDATE assessments SET not_for_issue_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0000' ", "SQL")
        end

        it "receives an appropriate error with a 404" do
          response = JSON.parse(
            bus_details_by_address(
              postcode: "A0 0AA",
              building_name_or_number: "1:",
              accepted_responses: [404],
            ).body,
            symbolize_names: true,
          )
          expect(response[:errors][0][:title]).to eq "No assessment details relevant to the BUS could be found for that query"
        end
      end
    end

    context "when there is one matching assessment to send BUS details for, but multiple for the same postcode" do
      before do
        xml = Nokogiri.XML rdsap_xml.dup

        lodge_assessment(
          assessment_body: rdsap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )

        xml.at("RRN").content = "2222-1111-2222-1111-2222"
        xml.at("UPRN").content = "UPRN-012340123456"
        xml.at_css("Property Address Address-Line-1").content = "20 Some Street"

        lodge_assessment(
          assessment_body: xml.to_s,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )
      end

      it "returns the matching assessment BUS details in the expected format" do
        response = JSON.parse(
          bus_details_by_address(
            postcode: "A0 0AA",
            building_name_or_number: "1",
          ).body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_rdsap_details
      end
    end

    context "when there are two matching assessments to send BUS details for" do
      before do
        lodge_assessment(
          assessment_body: rdsap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )

        xml = Nokogiri.XML rdsap_xml.dup

        xml.at("RRN").content = "0000-1111-2222-3333-4444"
        xml.at("UPRN").content = "UPRN-000222444666"

        lodge_assessment(
          assessment_body: xml.to_s,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-20.0.0",
        )
      end

      it "returns a list of assessment references with a 300 status code" do
        response = JSON.parse(
          bus_details_by_address(
            postcode: "A0 0AA",
            building_name_or_number: "1",
            accepted_responses: [300],
          ).body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq({
          links: {
            assessments: %w[0000-0000-0000-0000-0000 0000-1111-2222-3333-4444],
          },
        })
      end
    end

    context "when there are no matching assessments to send BUS details for" do
      it "receives an error response with a 404" do
        response = JSON.parse(
          bus_details_by_address(
            postcode: "A0 0AA",
            building_name_or_number: "1",
            accepted_responses: [404],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "No assessment details relevant to the BUS could be found for that query"
      end
    end

    context "when the postcode provided as part of the address is not valid" do
      it "receives an appropriate error with a 400" do
        response = JSON.parse(
          bus_details_by_address(
            postcode: "A0",
            building_name_or_number: "1",
            accepted_responses: [400],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "The value provided for the postcode parameter in the search query was not valid"
      end
    end

    context "when a postcode parameter is provided without a building name or number" do
      it "receives an appropriate error with a 400" do
        response = JSON.parse(
          bus_details_by_arbitrary_params(
            params: { postcode: "A0 0AA" },
            accepted_responses: [400],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "The search query was invalid - please check the provided parameters"
      end
    end
  end

  context "when performing a search using an RRN" do
    context "when an RRN is provided in a correct format that matches assessment BUS details that can be sent" do
      before do
        lodge_assessment(
          assessment_body: cepc_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "CEPC-8.0.0",
        )
      end

      it "receives a 200 with the assessment BUS details" do
        response = JSON.parse(
          bus_details_by_rrn(
            "0000-0000-0000-0000-0000",
          ).body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_cepc_details
      end
    end

    context "when an RRN is provided in a correct format, but does not match existing assessments for BUS" do
      it "receives a 404 with an appropriate error" do
        response = JSON.parse(
          bus_details_by_rrn(
            "0000-1111-2222-3333-4444",
            accepted_responses: [404],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "No assessment details relevant to the BUS could be found for that query"
      end
    end

    context "when an RRN is provided in an invalid format" do
      it "receives an appropriate error with a 400" do
        response = JSON.parse(
          bus_details_by_rrn(
            "00001111222233334444",
            accepted_responses: [400],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "The value provided for the rrn parameter in the search query was not valid"
      end
    end
  end

  context "when performing a search using a UPRN" do
    context "when a UPRN is provided in a valid format and pertains to existing assessments" do
      before do
        lodge_assessment(
          assessment_body: sap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-18.0.0",
        )
      end

      it "returns a 200 with the expected BUS details" do
        response = JSON.parse(
          bus_details_by_uprn(
            "UPRN-000000000000",
          ).body,
          symbolize_names: true,
        )

        expect(response[:data]).to eq expected_sap_details
      end
    end

    context "when a UPRN is provided in a valid format but does not pertain to an existing assessment BUS details can be sent for" do
      it "received an appropriate error with a 404" do
        response = JSON.parse(
          bus_details_by_uprn(
            "UPRN-123456789012",
            accepted_responses: [404],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "No assessment details relevant to the BUS could be found for that query"
      end
    end

    context "when a UPRN is provided in a valid format but is for a certificate that has been opted out" do
      before do
        lodge_assessment(
          assessment_body: sap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-18.0.0",
        )
        opt_out_assessment(assessment_id: "0000-0000-0000-0000-0000")
      end

      it "receives an appropriate error with a 404" do
        response = JSON.parse(
          bus_details_by_uprn(
            "UPRN-000000000000",
            accepted_responses: [404],
          ).body,
          symbolize_names: true,
        )
        expect(response[:errors][0][:title]).to eq "No assessment details relevant to the BUS could be found for that query"
      end
    end

    context "when a UPRN is provided in a valid format but is for a certificate that has been cancelled" do
      before do
        lodge_assessment(
          assessment_body: sap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-18.0.0",
        )
        ActiveRecord::Base.connection.exec_query("UPDATE assessments SET cancelled_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0000' ", "SQL")
      end

      it "receives an appropriate error with a 404" do
        response = JSON.parse(
          bus_details_by_uprn(
            "UPRN-000000000000",
            accepted_responses: [404],
          ).body,
          symbolize_names: true,
        )
        expect(response[:errors][0][:title]).to eq "No assessment details relevant to the BUS could be found for that query"
      end
    end

    context "when a UPRN is provided in a valid format but is for a certificate that has been marked as not for issue" do
      before do
        lodge_assessment(
          assessment_body: sap_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "SAP-Schema-18.0.0",
        )
        ActiveRecord::Base.connection.exec_query("UPDATE assessments SET not_for_issue_at = Now() WHERE assessment_id = '0000-0000-0000-0000-0000' ", "SQL")
      end

      it "receives an appropriate error with a 404" do
        response = JSON.parse(
          bus_details_by_uprn(
            "UPRN-000000000000",
            accepted_responses: [404],
          ).body,
          symbolize_names: true,
        )
        expect(response[:errors][0][:title]).to eq "No assessment details relevant to the BUS could be found for that query"
      end
    end

    context "when a UPRN is provided in an invalid format" do
      it "receives an appropriate error with a 400" do
        response = JSON.parse(
          bus_details_by_uprn(
            "UPRN-123456789",
            accepted_responses: [400],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "The value provided for the uprn parameter in the search query was not valid"
      end
    end

    context "when an RRN based address ID is provided for the UPRN field" do
      it "receives an appropriate error with a 400" do
        response = JSON.parse(
          bus_details_by_uprn(
            "RRN-0000-1111-2222-3333-4444",
            accepted_responses: [400],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:title]).to eq "The value provided for the uprn parameter in the search query was not valid"
      end
    end

    context "when a UPRN is provided but the auth scope is not correct" do
      it "receives a 403 with appropriate error" do
        response = JSON.parse(
          bus_details_by_uprn(
            "UPRN-000000000000",
            accepted_responses: [403],
            scopes: %w[wrong:scope],
          ).body,
          symbolize_names: true,
        )

        expect(response[:errors][0][:code]).to eq "UNAUTHORISED"
      end
    end
  end

  context "when performing a search with no query parameters" do
    it "receives an appropriate error with a 400" do
      response = JSON.parse(
        bus_details_by_arbitrary_params(
          params: {},
          accepted_responses: [400],
        ).body,
        symbolize_names: true,
      )

      expect(response[:errors][0][:title]).to eq "The search query was invalid - please check the provided parameters"
    end
  end
end
