describe "Acceptance::AddressSearch::ByStreetAndTown" do
  include RSpecAssessorServiceMixin

  let(:valid_cepc_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/CEPC-7.11(EPC).xml"
  end

  let(:valid_rdsap_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/RdSAP-19.01.xml"
  end

  let(:valid_assessor_request_body) do
    {
      firstName: "Someone",
      middleNames: "Muddle",
      lastName: "Person",
      dateOfBirth: "1991-02-25",
      searchResultsComparisonPostcode: "",
      qualifications: { domesticRdSap: "ACTIVE" },
      contactDetails: {
        telephoneNumber: "010199991010101", email: "person@person.com"
      },
    }
  end

  context "an address that has a report lodged" do
    before(:each) do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "TEST000000", valid_assessor_request_body)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      doc = Nokogiri.XML valid_rdsap_xml
      second_assessment = doc.dup
      third_assessment = doc.dup
      fourth_assessment = doc.dup

      assessment_id = second_assessment.at("RRN")
      assessment_id.children = "0000-0000-0000-0000-0001"

      address_line_one = second_assessment.search("Address-Line-1")[1]
      address_line_one.children = "2 Other Street"

      lodge_assessment(
        assessment_body: second_assessment.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      non_domestic_xml = Nokogiri.XML valid_cepc_xml

      assessment_id = non_domestic_xml.at("//CEPC:RRN")
      assessment_id.children = "0000-0000-0000-0000-0002"

      address_line_one = non_domestic_xml.at("//CEPC:Address-Line-1")
      address_line_one.children = "3 Other Street"

      scheme_assessor_id = non_domestic_xml.at("//CEPC:Certificate-Number")
      scheme_assessor_id.children = "TEST000000"

      lodge_assessment(
        assessment_body: non_domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )

      third_assessment_id = third_assessment.at("RRN")
      third_assessment_id.children = "0000-0000-0000-0000-0003"

      third_address_line_one = third_assessment.search("Address-Line-1")[1]
      third_address_line_one.children = "The House"
      third_address_line_two =
        Nokogiri::XML::Node.new "Address-Line-2", third_assessment
      third_address_line_two.content = "123 Test Street"
      third_address_line_one.add_next_sibling third_address_line_two

      lodge_assessment(
        assessment_body: third_assessment.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      fourth_assessment_id = fourth_assessment.at("RRN")
      fourth_assessment_id.children = "0000-0000-0000-0000-0004"

      fourth_address_line_one = fourth_assessment.search("Address-Line-1")[1]
      fourth_address_line_one.children = "3 Other Street"
      fourth_address_line_two =
        Nokogiri::XML::Node.new "Address-Line-2", fourth_assessment
      fourth_address_line_two.content = "Another Town"
      fourth_address_line_one.add_next_sibling fourth_address_line_two

      town = fourth_assessment.search("Post-Town")[1]
      town.children = "Some County"

      lodge_assessment(
        assessment_body: fourth_assessment.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )
    end

    describe "searching by street and town" do
      it "returns the address" do
        response =
          JSON.parse(
            assertive_get(
              "/api/search/addresses?street=Some%20Street&town=Post-Town1",
              [200],
              true,
              {},
              %w[address:search],
            )
              .body,
          )

        expect(response["data"]["addresses"].length).to eq 1
        expect(
          response["data"]["addresses"][0]["buildingReferenceNumber"],
        ).to eq "RRN-0000-0000-0000-0000-0000"
        expect(response["data"]["addresses"][0]["line1"]).to eq "1 Some Street"
        expect(response["data"]["addresses"][0]["town"]).to eq "Post-Town1"
        expect(response["data"]["addresses"][0]["postcode"]).to eq "A0 0AA"
        expect(
          response["data"]["addresses"][0]["source"],
        ).to eq "PREVIOUS_ASSESSMENT"
        expect(response["data"]["addresses"][0]["existingAssessments"]).to eq [
          "assessmentId" => "0000-0000-0000-0000-0000",
          "assessmentStatus" => "ENTERED",
          "assessmentType" => "RdSAP",
        ]
      end

      context "when an address type of domestic is provided" do
        it "returns the correct address" do
          response =
            JSON.parse(
              assertive_get(
                "/api/search/addresses?street=Some%20Street&town=Post-Town1&addressType=DOMESTIC",
                [200],
                true,
                {},
                %w[address:search],
              )
                .body,
            )

          expect(response["data"]["addresses"].length).to eq 1
          expect(
            response["data"]["addresses"][0]["buildingReferenceNumber"],
          ).to eq "RRN-0000-0000-0000-0000-0000"
          expect(
            response["data"]["addresses"][0]["line1"],
          ).to eq "1 Some Street"
          expect(response["data"]["addresses"][0]["town"]).to eq "Post-Town1"
          expect(response["data"]["addresses"][0]["postcode"]).to eq "A0 0AA"
          expect(
            response["data"]["addresses"][0]["source"],
          ).to eq "PREVIOUS_ASSESSMENT"
          expect(
            response["data"]["addresses"][0]["existingAssessments"],
          ).to eq [
            "assessmentId" => "0000-0000-0000-0000-0000",
            "assessmentStatus" => "ENTERED",
            "assessmentType" => "RdSAP",
          ]
        end
      end

      context "when an invalid address type is provided" do
        it "returns status 422" do
          assertive_get(
            "/api/search/addresses?street=Other%20Street&town=Post-Town1&addressType=asdf",
            [422],
            true,
            {},
            %w[address:search],
          )
        end
      end

      context "when an address type of commercial is provided" do
        it "returns the correct address" do
          response =
            JSON.parse(
              assertive_get(
                "/api/search/addresses?street=Other%20Street&town=Post-Town1&addressType=COMMERCIAL",
                [200],
                true,
                {},
                %w[address:search],
              )
                .body,
            )

          expect(response["data"]["addresses"].length).to eq 1
          expect(
            response["data"]["addresses"][0]["buildingReferenceNumber"],
          ).to eq "RRN-0000-0000-0000-0000-0002"
          expect(
            response["data"]["addresses"][0]["line1"],
          ).to eq "3 Other Street"
          expect(response["data"]["addresses"][0]["town"]).to eq "Post-Town1"
          expect(response["data"]["addresses"][0]["postcode"]).to eq "A0 0AA"
          expect(
            response["data"]["addresses"][0]["source"],
          ).to eq "PREVIOUS_ASSESSMENT"
          expect(
            response["data"]["addresses"][0]["existingAssessments"],
          ).to eq [
            "assessmentId" => "0000-0000-0000-0000-0002",
            "assessmentStatus" => "ENTERED",
            "assessmentType" => "CEPC",
          ]
        end
      end

      context "with street on address line 2" do
        it "returns the address" do
          response =
            JSON.parse(
              assertive_get(
                "/api/search/addresses?street=Test%20Street&town=Post-Town1",
                [200],
                true,
                {},
                %w[address:search],
              )
                .body,
            )

          expect(response["data"]["addresses"].length).to eq 1
          expect(
            response["data"]["addresses"][0]["buildingReferenceNumber"],
          ).to eq "RRN-0000-0000-0000-0000-0003"
          expect(response["data"]["addresses"][0]["line1"]).to eq "The House"
          expect(
            response["data"]["addresses"][0]["line2"],
          ).to eq "123 Test Street"
          expect(response["data"]["addresses"][0]["town"]).to eq "Post-Town1"
          expect(response["data"]["addresses"][0]["postcode"]).to eq "A0 0AA"
          expect(
            response["data"]["addresses"][0]["source"],
          ).to eq "PREVIOUS_ASSESSMENT"
          expect(
            response["data"]["addresses"][0]["existingAssessments"],
          ).to eq [
            "assessmentId" => "0000-0000-0000-0000-0003",
            "assessmentStatus" => "ENTERED",
            "assessmentType" => "RdSAP",
          ]
        end
      end

      context "with town on address line 2" do
        it "returns the address" do
          response =
            JSON.parse(
              assertive_get(
                "/api/search/addresses?street=Other%20Street&town=Another%20Town",
                [200],
                true,
                {},
                %w[address:search],
              )
                .body,
            )

          expect(response["data"]["addresses"].length).to eq 1
          expect(
            response["data"]["addresses"][0]["buildingReferenceNumber"],
          ).to eq "RRN-0000-0000-0000-0000-0004"
          expect(
            response["data"]["addresses"][0]["line1"],
          ).to eq "3 Other Street"
          expect(response["data"]["addresses"][0]["line2"]).to eq "Another Town"
          expect(response["data"]["addresses"][0]["town"]).to eq "Some County"
          expect(response["data"]["addresses"][0]["postcode"]).to eq "A0 0AA"
          expect(
            response["data"]["addresses"][0]["source"],
          ).to eq "PREVIOUS_ASSESSMENT"
          expect(
            response["data"]["addresses"][0]["existingAssessments"],
          ).to eq [
            "assessmentId" => "0000-0000-0000-0000-0004",
            "assessmentStatus" => "ENTERED",
            "assessmentType" => "RdSAP",
          ]
        end
      end
    end
  end
end
