describe "Acceptance::AddressSearch::ByPostcode" do
  include RSpecAssessorServiceMixin

  let(:valid_cepc_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml"
  end

  let(:valid_rdsap_xml) do
    File.read File.join Dir.pwd, "spec/fixtures/samples/rdsap.xml"
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
    let(:scheme_id) { add_scheme_and_get_id }

    before(:each) do
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      entered_assessment = Nokogiri.XML valid_rdsap_xml
      entered_assessment.at("UPRN").remove

      lodge_assessment(
        assessment_body: entered_assessment.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      doc = Nokogiri.XML valid_rdsap_xml

      assessment_id = doc.at("RRN")
      assessment_id.children = "0000-0000-0000-0000-0001"
      address_id = doc.at("UPRN")
      address_id.children = "RRN-0000-0000-0000-0000-0000"

      address_line_one = doc.search("Address-Line-1")[1]
      address_line_one.children = "2 Some Street"

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      non_domestic_xml = Nokogiri.XML valid_cepc_xml

      assessment_id = non_domestic_xml.at("//CEPC:RRN")
      assessment_id.children = "0000-0000-0000-0000-0002"

      address_line_one = non_domestic_xml.at("//CEPC:Address-Line-1")
      address_line_one.children = "3 Other Street"

      scheme_assessor_id = non_domestic_xml.at("//CEPC:Certificate-Number")
      scheme_assessor_id.children = "SPEC000000"

      lodge_assessment(
        assessment_body: non_domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-7.1",
      )

      third_assessment_id = doc.at("RRN")
      third_assessment_id.children = "0000-0000-0000-0000-0003"
      third_address_id = doc.at("UPRN")
      third_address_id.children = "RRN-0000-0000-0000-0000-0003"

      address_line_one = doc.search("Address-Line-1")[1]
      address_line_one.children = "The House"
      address_line_two = Nokogiri::XML::Node.new "Address-Line-2", doc
      address_line_two.content = "123 Test Street"
      address_line_one.add_next_sibling address_line_two

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      fourth_assessment_id = doc.at("RRN")
      fourth_assessment_id.children = "0000-0000-0000-0000-0004"
      fourth_address_id = doc.at("UPRN")
      fourth_address_id.children = "RRN-0000-0000-0000-0000-0003"

      assessment_date = doc.at("Inspection-Date")
      assessment_date.children = Date.today.prev_day.strftime("%Y-%m-%d")

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )
    end

    describe "searching by postcode" do
      context "when an invalid postcode is provided" do
        it "returns an unprocessable entity response" do
          assertive_get(
            "/api/search/addresses?postcode=INVALID_POSTCODE",
            [422],
            true,
            {},
            %w[address:search],
          )
        end
      end

      context "when a valid postcode is provided" do
        context "with an expired assessment" do
          let(:response) do
            JSON.parse(
              assertive_get(
                "/api/search/addresses?postcode=A0%200AA",
                [200],
                true,
                {},
                %w[address:search],
              )
                .body,
              symbolize_names: true,
            )
          end

          it "returns the expected amount of addresses" do
            expect(response[:data][:addresses].length).to eq 3
          end

          it "returns the address" do
            expect(response[:data][:addresses][0]).to eq(
              {
                addressId: "RRN-0000-0000-0000-0000-0001",
                line1: "1 Some Street",
                line2: nil,
                line3: nil,
                line4: nil,
                town: "Post-Town1",
                postcode: "A0 0AA",
                source: "PREVIOUS_ASSESSMENT",
                existingAssessments: [
                  {
                    assessmentId: "0000-0000-0000-0000-0001",
                    assessmentStatus: "EXPIRED",
                    assessmentType: "RdSAP",
                  },
                  {
                    assessmentId: "0000-0000-0000-0000-0000",
                    assessmentStatus: "EXPIRED",
                    assessmentType: "RdSAP",
                  },
                ],
              },
            )
          end
        end

        context "with an entered assessment" do
          let(:response) do
            JSON.parse(
              assertive_get(
                "/api/search/addresses?postcode=A0%200AA",
                [200],
                true,
                {},
                %w[address:search],
              )
                .body,
              symbolize_names: true,
            )
          end

          it "returns the expected amount of addresses" do
            expect(response[:data][:addresses].length).to eq 3
          end

          it "returns the expected address" do
            expect(response[:data][:addresses][2]).to eq(
              {
                addressId: "RRN-0000-0000-0000-0000-0004",
                line1: "The House",
                line2: "123 Test Street",
                line3: nil,
                line4: nil,
                town: "Post-Town1",
                postcode: "A0 0AA",
                source: "PREVIOUS_ASSESSMENT",
                existingAssessments: [
                  {
                    assessmentId: "0000-0000-0000-0000-0004",
                    assessmentStatus: "ENTERED",
                    assessmentType: "RdSAP",
                  },
                  {
                    assessmentId: "0000-0000-0000-0000-0003",
                    assessmentStatus: "EXPIRED",
                    assessmentType: "RdSAP",
                  },
                ],
              },
            )
          end
        end
      end

      context "when there is no space in the postcode" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?postcode=A00AA",
              [200],
              true,
              {},
              %w[address:search],
            )
              .body,
            symbolize_names: true,
          )
        end

        it "returns the expected amount of addresses" do
          expect(response[:data][:addresses].length).to eq 3
        end

        it "returns the address" do
          expect(response[:data][:addresses][0]).to eq(
            {
              addressId: "RRN-0000-0000-0000-0000-0001",
              line1: "1 Some Street",
              line2: nil,
              line3: nil,
              line4: nil,
              town: "Post-Town1",
              postcode: "A0 0AA",
              source: "PREVIOUS_ASSESSMENT",
              existingAssessments: [
                {
                  assessmentId: "0000-0000-0000-0000-0001",
                  assessmentStatus: "EXPIRED",
                  assessmentType: "RdSAP",
                },
                {
                  assessmentId: "0000-0000-0000-0000-0000",
                  assessmentStatus: "EXPIRED",
                  assessmentType: "RdSAP",
                },
              ],
            },
          )
        end
      end

      context "when building name or number is supplied" do
        describe "with slightly misspelled building name" do
          let(:response) do
            JSON.parse(
              assertive_get(
                "/api/search/addresses?postcode=A0%200AA&buildingNameNumber=The%20Huose",
                [200],
                true,
                {},
                %w[address:search],
              )
                .body,
              symbolize_names: true,
            )
          end

          it "returns the expected amount of addresses" do
            expect(response[:data][:addresses].length).to eq 3
          end

          it "returns the expected address" do
            expect(response[:data][:addresses][0]).to eq(
              {
                addressId: "RRN-0000-0000-0000-0000-0004",
                line1: "The House",
                line2: "123 Test Street",
                line3: nil,
                line4: nil,
                town: "Post-Town1",
                postcode: "A0 0AA",
                source: "PREVIOUS_ASSESSMENT",
                existingAssessments: [
                  {
                    assessmentId: "0000-0000-0000-0000-0004",
                    assessmentStatus: "ENTERED",
                    assessmentType: "RdSAP",
                  },
                  {
                    assessmentId: "0000-0000-0000-0000-0003",
                    assessmentStatus: "EXPIRED",
                    assessmentType: "RdSAP",
                  },
                ],
              },
            )
          end
        end

        describe "with a building number" do
          let(:response) do
            JSON.parse(
              assertive_get(
                "/api/search/addresses?postcode=A0%200AA&buildingNameNumber=2",
                [200],
                true,
                {},
                %w[address:search],
              )
                .body,
              symbolize_names: true,
            )
          end

          it "returns the expected amount of addresses" do
            expect(response[:data][:addresses].length).to eq 3
          end

          it "returns the expected address" do
            expect(response[:data][:addresses][0]).to eq(
              {
                addressId: "RRN-0000-0000-0000-0000-0001",
                line1: "2 Some Street",
                line2: nil,
                line3: nil,
                line4: nil,
                town: "Post-Town1",
                postcode: "A0 0AA",
                source: "PREVIOUS_ASSESSMENT",
                existingAssessments: [
                  {
                    assessmentId: "0000-0000-0000-0000-0001",
                    assessmentStatus: "EXPIRED",
                    assessmentType: "RdSAP",
                  },
                ],
              },
            )
          end
        end

        describe "with a building number on address line 2" do
          let(:response) do
            JSON.parse(
              assertive_get(
                "/api/search/addresses?postcode=A0%200AA&buildingNameNumber=123",
                [200],
                true,
                {},
                %w[address:search],
              )
                .body,
              symbolize_names: true,
            )
          end

          it "returns the expected amount of addresses" do
            expect(response[:data][:addresses].length).to eq 3
          end

          it "returns the expected address" do
            expect(response[:data][:addresses][1]).to eq(
              {
                addressId: "RRN-0000-0000-0000-0000-0004",
                line1: "The House",
                line2: "123 Test Street",
                line3: nil,
                line4: nil,
                town: "Post-Town1",
                postcode: "A0 0AA",
                source: "PREVIOUS_ASSESSMENT",
                existingAssessments: [
                  {
                    assessmentId: "0000-0000-0000-0000-0004",
                    assessmentStatus: "ENTERED",
                    assessmentType: "RdSAP",
                  },
                  {
                    assessmentId: "0000-0000-0000-0000-0003",
                    assessmentStatus: "EXPIRED",
                    assessmentType: "RdSAP",
                  },
                ],
              },
            )
          end
        end
      end

      context "when an invalid address type is provided" do
        it "returns status 422" do
          assertive_get(
            "/api/search/addresses?postcode=A0%200AA&addressType=asdf",
            [422],
            true,
            {},
            %w[address:search],
          )
        end
      end

      context "when an address type of domestic is provided" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?postcode=A0%200AA&addressType=DOMESTIC",
              [200],
              true,
              {},
              %w[address:search],
            )
              .body,
            symbolize_names: true,
          )
        end

        it "returns the expected amount of addresses" do
          expect(response[:data][:addresses].length).to eq 2
        end

        it "returns the expected address" do
          expect(response[:data][:addresses][0]).to eq(
            {
              addressId: "RRN-0000-0000-0000-0000-0001",
              line1: "1 Some Street",
              line2: nil,
              line3: nil,
              line4: nil,
              town: "Post-Town1",
              postcode: "A0 0AA",
              source: "PREVIOUS_ASSESSMENT",
              existingAssessments: [
                {
                  assessmentId: "0000-0000-0000-0000-0001",
                  assessmentStatus: "EXPIRED",
                  assessmentType: "RdSAP",
                },
                {
                  assessmentId: "0000-0000-0000-0000-0000",
                  assessmentStatus: "EXPIRED",
                  assessmentType: "RdSAP",
                },
              ],
            },
          )
        end
      end

      context "when an address type of commercial is provided" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?postcode=A0%200AA&addressType=COMMERCIAL",
              [200],
              true,
              {},
              %w[address:search],
            )
              .body,
            symbolize_names: true,
          )
        end

        it "returns the expected amount of addresses" do
          expect(response[:data][:addresses].length).to eq 1
        end

        it "returns the expected address" do
          expect(response[:data][:addresses][0]).to eq(
            {
              addressId: "RRN-0000-0000-0000-0000-0002",
              line1: "3 Other Street",
              line2: nil,
              line3: nil,
              line4: nil,
              town: "Post-Town1",
              postcode: "A0 0AA",
              source: "PREVIOUS_ASSESSMENT",
              existingAssessments: [
                {
                  assessmentId: "0000-0000-0000-0000-0002",
                  assessmentStatus: "EXPIRED",
                  assessmentType: "CEPC",
                },
              ],
            },
          )
        end
      end
    end
  end
end
