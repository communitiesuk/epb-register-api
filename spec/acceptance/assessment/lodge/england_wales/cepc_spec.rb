# frozen_string_literal: true

describe "Acceptance::LodgeCEPCEnergyAssessment" do
  include RSpecAssessorServiceMixin

  let(:fetch_assessor_stub) { AssessorStub.new }

  let(:valid_cepc_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml"
  end

  context "when lodging a CEPC assessment (post)" do
    context "when an assessor is inactive" do
      let(:scheme_id) { add_scheme_and_get_id }

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(
            nonDomesticNos3: "INACTIVE",
            nonDomesticNos4: "INACTIVE",
            nonDomesticNos5: "INACTIVE",
          ),
        )
      end

      context "when unqualified for NOS3, NOS4 and NOS5" do
        it "returns status 400 with the correct error response" do
          response =
            JSON.parse(
              lodge_assessment(
                assessment_body: valid_cepc_xml,
                accepted_responses: [400],
                auth_data: { scheme_ids: [scheme_id] },
                schema_name: "CEPC-7.1",
              ).body,
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
            assessment_body: doc.to_xml,
            accepted_responses: [400],
            auth_data: { scheme_ids: [scheme_id] },
            schema_name: "CEPC-7.1",
          )
        end
      end
    end

    it "returns status 201" do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "SPEC000000",
        fetch_assessor_stub.fetch_request_body(
          nonDomesticNos3: "ACTIVE", nonDomesticNos4: "ACTIVE",
        ),
      )

      lodge_assessment(
        assessment_body: valid_cepc_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )
    end

    context "when saving a (CEPC) assessment" do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_cepc_xml }
      let(:response) do
        JSON.parse(fetch_assessment("0000-0000-0000-0000-0000").body)
      end

      before do
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(
            nonDomesticNos3: "ACTIVE", nonDomesticNos4: "ACTIVE",
          ),
        )
      end

      it "returns the data that was lodged" do
        lodge_assessment(
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-7.1",
        )

        expected_response = {
          "addressId" => "UPRN-000000000001",
          "addressLine1" => "2 Lonely Street",
          "addressLine2" => "",
          "addressLine3" => "",
          "addressLine4" => "",
          "assessmentId" => "0000-0000-0000-0000-0000",
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
            "schemeAssessorId" => "SPEC000000",
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
          "relatedAssessments" => [
            {
              "assessmentExpiryDate" => "2016-05-04",
              "assessmentId" => "0000-0000-0000-0000-0000",
              "assessmentStatus" => "EXPIRED",
              "assessmentType" => "CEPC",
            },
          ],
        }

        expect(response["data"]).to eq(expected_response)
      end

      it "can return the correct second address line of the property" do
        address_line_one = doc.search("//CEPC:Address-Line-1")[0]
        address_line_two = Nokogiri::XML::Node.new "CEPC:Address-Line-2", doc
        address_line_two.content = "2 test street"
        address_line_one.add_next_sibling address_line_two

        lodge_assessment(
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
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: "CEPC-7.1",
        )

        expect(response["data"]["addressLine3"]).to eq("3 test street")
      end

      context "when missing optional elements" do
        it "can return an empty string for address lines" do
          lodge_assessment(
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
    end

    context "when rejecting an assessment" do
      it "rejects an assessment without an address" do
        scheme_id = add_scheme_and_get_id
        add_assessor(
          scheme_id,
          "SPEC000000",
          fetch_assessor_stub.fetch_request_body(
            nonDomesticNos3: "ACTIVE",
            nonDomesticNos4: "ACTIVE",
            nonDomesticNos5: "ACTIVE",
          ),
        )

        doc = Nokogiri.XML valid_cepc_xml

        scheme_assessor_id = doc.at("//CEPC:Property-Address")
        scheme_assessor_id.children = ""

        lodge_assessment(
          assessment_body: doc.to_xml,
          accepted_responses: [400],
          schema_name: "CEPC-7.1",
        )
      end
    end
  end
end
