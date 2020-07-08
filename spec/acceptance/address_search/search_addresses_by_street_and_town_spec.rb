describe "Acceptance::AddressSearch::ByStreetAndTown" do
  include RSpecRegisterApiServiceMixin

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

    let(:assessment) { Nokogiri.XML valid_rdsap_xml }
    let(:expired_assessment) { Nokogiri.XML valid_rdsap_xml }
    let(:address_id) { assessment.at("UPRN") }
    let(:assessment_id) { assessment.at("RRN") }
    let(:assessment_date) { assessment.at("Inspection-Date") }
    let(:address_line_one) { assessment.search("Address-Line-1")[1] }
    let(:address_line_two) do
      Nokogiri::XML::Node.new "Address-Line-2", assessment
    end
    let(:address_line_three) do
      Nokogiri::XML::Node.new "Address-Line-3", assessment
    end
    let(:address_line_four) do
      Nokogiri::XML::Node.new "Address-Line-3", assessment
    end
    let(:town) { assessment.search("Post-Town")[1] }

    let(:non_domestic_xml) { Nokogiri.XML valid_cepc_xml }
    let(:cepc_assessment_id) { non_domestic_xml.at("//CEPC:RRN") }
    let(:cepc_address_line_one) { non_domestic_xml.at("//CEPC:Address-Line-1") }

    before(:each) do
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      expired_assessment.at("UPRN").remove

      lodge_assessment(
        assessment_body: expired_assessment.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      assessment_id.children = "0000-0000-0000-0000-0001"
      address_line_one.children = "2 Other Street"

      lodge_assessment(
        assessment_body: assessment.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      cepc_assessment_id.children = "0000-0000-0000-0000-0002"
      cepc_address_line_one.children = "3 Other Street"

      lodge_assessment(
        assessment_body: non_domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )

      assessment_id.children = "0000-0000-0000-0000-0003"
      address_line_one.children = "The House"
      address_line_two.content = "123 Test Street"
      address_line_one.add_next_sibling address_line_two

      lodge_assessment(
        assessment_body: assessment.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      assessment_id.children = "0000-0000-0000-0000-0004"
      address_line_one.children = "3 Other Street"
      address_line_two.content = nil
      address_line_one.add_next_sibling address_line_two
      address_line_three.content = "Another Town"
      address_line_two.add_next_sibling address_line_three
      town.children = "Some County"

      lodge_assessment(
        assessment_body: assessment.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
      )

      assessment_id.children = "0000-0000-0000-0000-0005"
      address_id.children = "RRN-0000-0000-0000-0000-0000"
      address_line_two.content = nil
      address_line_one.add_next_sibling address_line_two
      assessment_date.children = Date.today.prev_day.strftime("%Y-%m-%d")

      lodge_assessment(
        assessment_body: assessment.to_xml,
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
            ).body,
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

      context "when town is slightly misspelled" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?street=Some%20Street&town=Psot-Town1",
              [200],
              true,
              {},
              %w[address:search],
            ).body,
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

      context "with an expired assessment" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?street=Some%20Street&town=Post-Town1",
              [200],
              true,
              {},
              %w[address:search],
            ).body,
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

      context "with a cancelled assessment" do
        it "returns the expected amount of addresses" do
          response =
            JSON.parse(
              assertive_get(
                "/api/search/addresses?street=Some%20Street&town=Post-Town1",
                [200],
                true,
                {},
                %w[address:search],
              ).body,
              symbolize_names: true,
            )

          expect(response[:data][:addresses].length).to eq 1

          update_assessment_status(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_status_body: { status: "CANCELLED" },
            auth_data: { scheme_ids: [scheme_id] },
            accepted_responses: [200],
          )

          response =
            JSON.parse(
              assertive_get(
                "/api/search/addresses?street=Some%20Street&town=Post-Town1",
                [200],
                true,
                {},
                %w[address:search],
              ).body,
              symbolize_names: true,
            )
          expect(response[:data][:addresses].length).to eq 0
        end
      end

      context "with a not-for-issue assessment" do
        it "returns the expected amount of addresses" do
          response =
            JSON.parse(
              assertive_get(
                "/api/search/addresses?street=Some%20Street&town=Post-Town1",
                [200],
                true,
                {},
                %w[address:search],
              ).body,
              symbolize_names: true,
            )

          expect(response[:data][:addresses].length).to eq 1

          update_assessment_status(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_status_body: { status: "NOT_FOR_ISSUE" },
            auth_data: { scheme_ids: [scheme_id] },
            accepted_responses: [200],
          )

          response =
            JSON.parse(
              assertive_get(
                "/api/search/addresses?street=Some%20Street&town=Post-Town1",
                [200],
                true,
                {},
                %w[address:search],
              ).body,
              symbolize_names: true,
            )
          expect(response[:data][:addresses].length).to eq 0
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
            ).body,
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
                {
                  assessmentId: "0000-0000-0000-0000-0000",
                  assessmentStatus: "EXPIRED",
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
              ).body,
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
            ).body,
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
            ).body,
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
            ).body,
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

      context "with town on address line 3" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?street=Other%20Street&town=Another%20Town",
              [200],
              true,
              {},
              %w[address:search],
            ).body,
            symbolize_names: true,
          )
        end

        it "returns the expected amount of addresses" do
          expect(response[:data][:addresses].length).to eq 2
        end

        it "returns the expected addresses" do
          expect(response[:data][:addresses]).to eq(
            [
              {
                addressId: "RRN-0000-0000-0000-0000-0004",
                line1: "3 Other Street",
                line2: nil,
                line3: "Another Town",
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
              {
                addressId: "RRN-0000-0000-0000-0000-0005",
                line1: "3 Other Street",
                line2: nil,
                line3: "Another Town",
                line4: nil,
                town: "Some County",
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
            ],
          )
        end
      end
    end
  end
end
