# frozen_string_literal: true

describe "Acceptance::LodgeCEPCEnergyAssessment" do
  include RSpecAssessorServiceMixin

  let(:valid_assessor_request_body) do
    {
      firstName: "Someone",
      middleNames: "Muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "",
      qualifications: {
        domesticSap: "INACTIVE",
        domesticRdSap: "INACTIVE",
        nonDomesticSp3: "INACTIVE",
        nonDomesticCc4: "INACTIVE",
        nonDomesticDec: "INACTIVE",
        nonDomesticNos3: "ACTIVE",
        nonDomesticNos4: "ACTIVE",
        nonDomesticNos5: "INACTIVE",
        gda: "INACTIVE",
      },
      contactDetails: {
        telephoneNumber: "010199991010101", email: "person@person.com"
      },
    }
  end

  let(:inactive_assessor_request_body) do
    {
      firstName: "Someone",
      middleNames: "Muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "",
      qualifications: {
        nonDomesticNos3: "INACTIVE",
        nonDomesticNos4: "INACTIVE",
        nonDomesticNos5: "INACTIVE",
      },
      contactDetails: {
        telephoneNumber: "010199991010101", email: "person@person.com"
      },
    }
  end

  let(:valid_cepc_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/CEPC-7.11 (EPC).xml"
  end

  context "when lodging a CEPC assessment (post)" do
    it "rejects an assessment with a schema that does not exist" do
      lodge_assessment(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_body: valid_cepc_xml,
        accepted_responses: [400],
        schema_name: "Madeup-schema",
      )
    end

    context "when an assessor is not registered" do
      it "returns status 400 with the correct error response" do
        response =
          JSON.parse(
            lodge_assessment(
              assessment_id: "0000-0000-0000-0000-0000",
              assessment_body: valid_cepc_xml,
              accepted_responses: [400],
              schema_name: "CEPC-7.1",
            )
              .body,
          )

        expect(response["errors"][0]["title"]).to eq(
          "Assessor is not registered.",
        )
      end
    end

    context "when an assessor is inactive" do
      let(:scheme_id) { add_scheme_and_get_id }

      before do
        add_assessor(scheme_id, "JASE000000", inactive_assessor_request_body)
      end

      context "when unqualified for NOS3, NOS4 and NOS5" do
        it "returns status 400 with the correct error response" do
          response =
            JSON.parse(
              lodge_assessment(
                assessment_id: "0000-0000-0000-0000-0000",
                assessment_body: valid_cepc_xml,
                accepted_responses: [400],
                auth_data: { scheme_ids: [scheme_id] },
                schema_name: "CEPC-7.1",
              )
                .body,
            )

          expect(response["errors"][0]["title"]).to eq(
            "Assessor is not active.",
          )
        end
      end

      context "when missing building complexity element" do
        it "can return status 400 with the correct error response" do
          doc = Nokogiri.XML valid_cepc_xml

          doc.at("//CEPC:Building-Complexity").remove

          lodge_assessment(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_body: doc.to_xml,
            accepted_responses: [400],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "CEPC-7.1",
          )
        end
      end
    end

    it "returns 401 with no authentication" do
      lodge_assessment(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_body: "body",
        accepted_responses: [401],
        authenticate: false,
        schema_name: "CEPC-7.1",
      )
    end

    it "returns 403 with incorrect scopes" do
      lodge_assessment(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_body: "body",
        accepted_responses: [403],
        auth_data: { scheme_ids: {} },
        scopes: %w[wrong:scope],
        schema_name: "CEPC-7.1",
      )
    end

    it "returns 403 if it is being lodged by the wrong scheme" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "JASE000000", valid_assessor_request_body)
      different_scheme_id = add_scheme_and_get_id("BADSCHEME")

      lodge_assessment(
        assessment_id: "123-344",
        assessment_body: valid_cepc_xml,
        accepted_responses: [403],
        auth_data: { scheme_ids: [different_scheme_id] },
        schema_name: "CEPC-7.1",
      )
    end

    it "returns status 201" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "JASE000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_body: valid_cepc_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )
    end

    it "returns json" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "JASE000000", valid_assessor_request_body)

      response =
        lodge_assessment(
          assessment_id: "0000-0000-0000-0000-0000",
          assessment_body: valid_cepc_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-7.1",
        )

      expect(response.headers["Content-Type"]).to eq("application/json")
    end

    it "returns the assessment as a hash" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "JASE000000", valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_body: valid_cepc_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "CEPC-7.1",
          )
            .body,
          symbolize_names: true,
        )

      expect(response[:data]).to be_a Hash
    end

    it "returns the assessment with the correct keys" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "JASE000000", valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_body: valid_cepc_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "CEPC-7.1",
          )
            .body,
          symbolize_names: true,
        )

      expect(response[:data].keys).to match_array(
        %i[
          dateOfAssessment
          dateRegistered
          dwellingType
          typeOfAssessment
          totalFloorArea
          assessmentId
          schemeAssessorId
          addressSummary
          currentEnergyEfficiencyRating
          potentialEnergyEfficiencyRating
          currentCarbonEmission
          potentialCarbonEmission
          optOut
          postcode
          dateOfExpiry
          addressLine1
          addressLine2
          addressLine3
          addressLine4
          town
          heatDemand
          currentEnergyEfficiencyBand
          potentialEnergyEfficiencyBand
          recommendedImprovements
          propertySummary
          relatedPartyDisclosureNumber
          relatedPartyDisclosureText
        ],
      )
    end

    it "returns the correct scheme assessor id" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "JASE000000", valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_body: valid_cepc_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "CEPC-7.1",
          )
            .body,
          symbolize_names: true,
        )

      expect(response.dig(:data, :schemeAssessorId)).to eq("JASE000000")
    end

    context "when schema is not supported" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_cepc_xml }

      before do
        add_assessor(scheme_id, "TEST123456", valid_assessor_request_body)

        assessment_id = doc.at("//CEPC:RRN")
        assessment_id.children = "1234-1234-1234-1234-1234"

        scheme_assessor_id = doc.at("//CEPC:Certificate-Number")
        scheme_assessor_id.children = "JASE000000"
      end

      it "returns status 400" do
        lodge_assessment(
          assessment_id: "1234-1234-1234-1234-1234",
          assessment_body: doc.to_xml,
          accepted_responses: [400],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "unsupported",
        )
      end

      it "returns the correct error message" do
        response =
          JSON.parse(
            lodge_assessment(
              assessment_id: "1234-1234-1234-1234-1234",
              assessment_body: doc.to_xml,
              accepted_responses: [400],
              auth_data: { scheme_ids: [scheme_id] },
              schema_name: "unsupported",
            )
              .body,
          )

        expect(response["errors"][0]["title"]).to eq("Schema is not supported.")
      end
    end

    context "when saving a (CEPC) assessment" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_cepc_xml }
      let(:response) do
        JSON.parse(fetch_assessment("1234-1234-1234-1234-1234").body)
      end

      before do
        add_assessor(scheme_id, "JASE000000", valid_assessor_request_body)

        assessment_id = doc.at("//CEPC:RRN")
        assessment_id.children = "1234-1234-1234-1234-1234"

        scheme_assessor_id = doc.at("//CEPC:Certificate-Number")
        scheme_assessor_id.children = "JASE000000"
      end

      context "when an assessment id does not match" do
        it "returns status 422" do
          lodge_assessment(
            assessment_id: "123-456",
            assessment_body: doc.to_xml,
            accepted_responses: [422],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "CEPC-7.1",
          )
        end
      end

      context "when an assessment already exists with the same assessment id" do
        it "returns status 409" do
          lodge_assessment(
            assessment_id: "1234-1234-1234-1234-1234",
            assessment_body: doc.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "CEPC-7.1",
          )

          lodge_assessment(
            assessment_id: "1234-1234-1234-1234-1234",
            assessment_body: doc.to_xml,
            accepted_responses: [409],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "CEPC-7.1",
          )
        end
      end

      it "returns the data that was lodged" do
        lodge_assessment(
          assessment_id: "1234-1234-1234-1234-1234",
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-7.1",
        )

        expected_response = {
          "addressLine1" => "2 Lonely Street",
          "addressLine2" => "",
          "addressLine3" => "",
          "addressLine4" => "",
          "addressSummary" => "2 Lonely Street, Post-Town1, A0 0AA",
          "assessmentId" => "1234-1234-1234-1234-1234",
          "assessor" => {
            "contactDetails" => {
              "email" => "person@person.com",
              "telephoneNumber" => "010199991010101",
            },
            "dateOfBirth" => "1991-02-25",
            "firstName" => "Someone",
            "lastName" => "Person",
            "middleNames" => "Muddle",
            "qualifications" => {
              "domesticSap" => "INACTIVE",
              "domesticRdSap" => "INACTIVE",
              "nonDomesticCc4" => "INACTIVE",
              "nonDomesticSp3" => "INACTIVE",
              "nonDomesticDec" => "INACTIVE",
              "nonDomesticNos3" => "ACTIVE",
              "nonDomesticNos4" => "ACTIVE",
              "nonDomesticNos5" => "INACTIVE",
              "gda" => "INACTIVE",
            },
            "address" => {},
            "companyDetails" => {},
            "registeredBy" => {
              "name" => "test scheme", "schemeId" => scheme_id
            },
            "schemeAssessorId" => "JASE000000",
            "searchResultsComparisonPostcode" => "",
          },
          "currentCarbonEmission" => 0.0,
          "currentEnergyEfficiencyBand" => "a",
          "currentEnergyEfficiencyRating" => 99,
          "optOut" => false,
          "dateOfAssessment" => "2006-05-04",
          "dateOfExpiry" => "2016-05-04",
          "dateRegistered" => "2006-05-04",
          "dwellingType" => nil,
          "heatDemand" => {
            "currentSpaceHeatingDemand" => 0.0,
            "currentWaterHeatingDemand" => 0.0,
            "impactOfCavityInsulation" => nil,
            "impactOfLoftInsulation" => nil,
            "impactOfSolidWallInsulation" => nil,
          },
          "postcode" => "A0 0AA",
          "potentialCarbonEmission" => 0.0,
          "potentialEnergyEfficiencyBand" => "a",
          "potentialEnergyEfficiencyRating" => 99,
          "totalFloorArea" => 99.0,
          "town" => "Post-Town1",
          "typeOfAssessment" => "CEPC",
          "relatedPartyDisclosureNumber" => nil,
          "relatedPartyDisclosureText" => nil,
          "recommendedImprovements" => [],
          "propertySummary" => [],
        }

        expect(response["data"]).to eq(expected_response)
      end

      it "can return the correct second address line of the property" do
        address_line_one = doc.search("//CEPC:Address-Line-1")[0]
        address_line_two = Nokogiri::XML::Node.new "CEPC:Address-Line-2", doc
        address_line_two.content = "2 test street"
        address_line_one.add_next_sibling address_line_two

        lodge_assessment(
          assessment_id: "1234-1234-1234-1234-1234",
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-7.1",
        )

        expect(response["data"]["addressLine2"]).to eq("2 test street")
      end

      it "can return the correct third address line of the property" do
        address_line_one = doc.search("//CEPC:Address-Line-1")[0]
        address_line_three = Nokogiri::XML::Node.new "CEPC:Address-Line-3", doc
        address_line_three.content = "3 test street"
        address_line_one.add_next_sibling address_line_three

        lodge_assessment(
          assessment_id: "1234-1234-1234-1234-1234",
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-7.1",
        )

        expect(response["data"]["addressLine3"]).to eq("3 test street")
      end

      it "can return the correct address summary of the property" do
        address_line_one = doc.search("//CEPC:Address-Line-1")[0]

        address_line_two = Nokogiri::XML::Node.new "CEPC:Address-Line-2", doc
        address_line_two.content = "2 test street"
        address_line_one.add_next_sibling address_line_two

        address_line_three = Nokogiri::XML::Node.new "CEPC:Address-Line-3", doc
        address_line_three.content = "3 test street"
        address_line_two.add_next_sibling address_line_three

        lodge_assessment(
          assessment_id: "1234-1234-1234-1234-1234",
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-7.1",
        )

        expect(response["data"]["addressSummary"]).to eq(
          "2 Lonely Street, 2 test street, 3 test street, Post-Town1, A0 0AA",
        )
      end

      context "when missing optional elements" do
        it "can return an empty string for address lines" do
          lodge_assessment(
            assessment_id: "1234-1234-1234-1234-1234",
            assessment_body: doc.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "CEPC-7.1",
          )
          expect(response["data"]["addressLine2"]).to eq("")
          expect(response["data"]["addressLine3"]).to eq("")
          expect(response["data"]["addressLine4"]).to eq("")
        end
      end

      context "when assessment xml is stored" do
        it "is visible when peeking into the assessments_xml table" do
          lodge_assessment(
            assessment_id: "1234-1234-1234-1234-1234",
            assessment_body: doc.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "CEPC-7.1",
          )

          results =
            ActiveRecord::Base.connection.execute(
              "SELECT xml FROM assessments_xml WHERE assessment_id = '" +
                ActiveRecord::Base.sanitize_sql("1234-1234-1234-1234-1234") +
                "'",
            )

          xml = ""
          results.each { |row| xml = row["xml"] }

          expect(doc.to_xml).to eq(
            '<?xml version="1.0" encoding="UTF-8"?>
' + xml,
          )
        end
      end
    end

    context "when rejecting an assessment" do
      it "rejects an assessment without an address" do
        scheme_id = add_scheme_and_get_id
        add_assessor(scheme_id, "JASE000000", valid_assessor_request_body)

        doc = Nokogiri.XML valid_cepc_xml

        scheme_assessor_id = doc.at("//CEPC:Property-Address")
        scheme_assessor_id.children = ""

        lodge_assessment(
          assessment_id: "0000-0000-0000-0000-0000",
          assessment_body: doc.to_xml,
          accepted_responses: [400],
          schema_name: "CEPC-7.1",
        )
      end

      it "rejects an assessment with an incorrect element" do
        scheme_id = add_scheme_and_get_id
        add_assessor(scheme_id, "JASE000000", valid_assessor_request_body)

        doc = Nokogiri.XML valid_cepc_xml

        address = doc.at("//CEPC:Property-Address")
        address.children = "<CEPC:Postcode>invalid</CEPC:Postcode>"

        response_body =
          JSON.parse(
            lodge_assessment(
              assessment_id: "0000-0000-0000-0000-0000",
              assessment_body: doc.to_xml,
              accepted_responses: [400],
              schema_name: "CEPC-7.1",
            )
              .body,
          )

        expect(
          response_body["errors"][0]["title"],
        ).to include "This element is not expected."
      end

      it "rejects an assessment with invalid XML" do
        scheme_id = add_scheme_and_get_id
        add_assessor(scheme_id, "JASE000000", valid_assessor_request_body)

        xml = valid_cepc_xml

        xml = xml.gsub("<CEPC:Report-Header>", "<Report-Header")

        response_body =
          JSON.parse(
            lodge_assessment(
              assessment_id: "0000-0000-0000-0000-0000",
              assessment_body: xml,
              accepted_responses: [400],
              schema_name: "CEPC-7.1",
            )
              .body,
          )

        expect(
          response_body["errors"][0]["title"],
        ).to include "Invalid attribute name: <<CEPC:RRN>"
      end
    end
  end
end
