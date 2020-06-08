describe "Acceptance::AddressSearch::ByStreetAndTown" do
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

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      doc = Nokogiri.XML valid_rdsap_xml
      second_assessment = doc.dup
      third_assessment = doc.dup
      fourth_assessment = doc.dup
      fifth_assessment = doc.dup

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

      fifth_assessment_id = fifth_assessment.at("RRN")
      fifth_assessment_id.children = "0000-0000-0000-0000-0005"

      assessment_date = fifth_assessment.at("Inspection-Date")
      assessment_date.children = Date.today.prev_day.strftime("%Y-%m-%d")

      lodge_assessment(
        assessment_body: fifth_assessment.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )
    end

    describe "searching by street and town" do
      context "when street is slightly misspelled" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?street=Seom%20Street&town=Post-Town1",
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
              addressId: "RRN-0000-0000-0000-0000-0005",
              line1: "1 Some Street",
              line2: nil,
              line3: nil,
              line4: nil,
              town: "Post-Town1",
              postcode: "A0 0AA",
              source: "PREVIOUS_ASSESSMENT",
              existingAssessments: [
                {
                  assessmentId: "0000-0000-0000-0000-0005",
                  assessmentStatus: "ENTERED",
                  assessmentType: "RdSAP",
                },
              ],
            },
          )
        end
      end

      context "when town is slightly misspelled" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?street=Some%20Street&town=Psot-Town1",
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
              addressId: "RRN-0000-0000-0000-0000-0005",
              line1: "1 Some Street",
              line2: nil,
              line3: nil,
              line4: nil,
              town: "Post-Town1",
              postcode: "A0 0AA",
              source: "PREVIOUS_ASSESSMENT",
              existingAssessments: [
                {
                  assessmentId: "0000-0000-0000-0000-0005",
                  assessmentStatus: "ENTERED",
                  assessmentType: "RdSAP",
                },
              ],
            },
          )
        end
      end

      context "with an expired assessment" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?street=Some%20Street&town=Post-Town1",
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
              addressId: "RRN-0000-0000-0000-0000-0005",
              line1: "1 Some Street",
              line2: nil,
              line3: nil,
              line4: nil,
              town: "Post-Town1",
              postcode: "A0 0AA",
              source: "PREVIOUS_ASSESSMENT",
              existingAssessments: [
                {
                  assessmentId: "0000-0000-0000-0000-0005",
                  assessmentStatus: "ENTERED",
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
              "/api/search/addresses?street=Some%20Street&town=Post-Town1",
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
              addressId: "RRN-0000-0000-0000-0000-0005",
              line1: "1 Some Street",
              line2: nil,
              line3: nil,
              line4: nil,
              town: "Post-Town1",
              postcode: "A0 0AA",
              source: "PREVIOUS_ASSESSMENT",
              existingAssessments: [
                {
                  assessmentId: "0000-0000-0000-0000-0005",
                  assessmentStatus: "ENTERED",
                  assessmentType: "RdSAP",
                },
              ],
            },
          )
        end

        context "when the town name is not in the same case as the search string" do
          let(:response) do
            JSON.parse(
              assertive_get(
                "/api/search/addresses?street=Some%20Street&town=POST-TOWN1",
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
                addressId: "RRN-0000-0000-0000-0000-0005",
                line1: "1 Some Street",
                line2: nil,
                line3: nil,
                line4: nil,
                town: "Post-Town1",
                postcode: "A0 0AA",
                source: "PREVIOUS_ASSESSMENT",
                existingAssessments: [
                  {
                    assessmentId: "0000-0000-0000-0000-0005",
                    assessmentStatus: "ENTERED",
                    assessmentType: "RdSAP",
                  },
                ],
              },
            )
          end
        end
      end

      context "when an address type of domestic is provided" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?street=Some%20Street&town=Post-Town1&addressType=DOMESTIC",
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
              addressId: "RRN-0000-0000-0000-0000-0005",
              line1: "1 Some Street",
              line2: nil,
              line3: nil,
              line4: nil,
              town: "Post-Town1",
              postcode: "A0 0AA",
              source: "PREVIOUS_ASSESSMENT",
              existingAssessments: [
                {
                  assessmentId: "0000-0000-0000-0000-0005",
                  assessmentStatus: "ENTERED",
                  assessmentType: "RdSAP",
                },
              ],
            },
          )
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
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?street=Other%20Street&town=Post-Town1&addressType=COMMERCIAL",
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

      context "with street on address line 2" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?street=Test%20Street&town=Post-Town1",
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
              addressId: "RRN-0000-0000-0000-0000-0003",
              line1: "The House",
              line2: "123 Test Street",
              line3: nil,
              line4: nil,
              town: "Post-Town1",
              postcode: "A0 0AA",
              source: "PREVIOUS_ASSESSMENT",
              existingAssessments: [
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

      context "with town on address line 2" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?street=Other%20Street&town=Another%20Town",
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
              addressId: "RRN-0000-0000-0000-0000-0004",
              line1: "3 Other Street",
              line2: "Another Town",
              line3: nil,
              line4: nil,
              town: "Some County",
              postcode: "A0 0AA",
              source: "PREVIOUS_ASSESSMENT",
              existingAssessments: [
                {
                  assessmentId: "0000-0000-0000-0000-0004",
                  assessmentStatus: "EXPIRED",
                  assessmentType: "RdSAP",
                },
              ],
            },
          )
        end
      end
    end
  end
end
