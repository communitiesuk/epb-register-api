describe "Acceptance::AddressSearch::ByStreetAndTown", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:valid_cepc_xml) { Samples.xml "CEPC-8.0.0", "cepc" }

  context "an address that has a report lodged" do
    let(:scheme_id) { add_scheme_and_get_id }

    let(:assessment) { Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0" }
    let(:expired_assessment) { Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0" }
    let(:address_id) { assessment.at("UPRN") }
    let(:assessment_id) { assessment.at("RRN") }
    let(:assessment_date) { assessment.at("Registration-Date") }
    let(:address_line_one) { assessment.search("Address-Line-1")[1] }
    let(:address_line_two) do
      Nokogiri::XML::Node.new "Address-Line-2", assessment
    end
    let(:town) { assessment.search("Post-Town")[1] }

    let(:non_domestic_xml) { Nokogiri.XML valid_cepc_xml }
    let(:cepc_assessment_id) { non_domestic_xml.at("//CEPC:RRN") }
    let(:cepc_address_line_one) { non_domestic_xml.at("//CEPC:Address-Line-1") }
    let(:cepc_address_line_two) { non_domestic_xml.at("//CEPC:Address-Line-2") }
    let(:cepc_address_line_three) do
      non_domestic_xml.at("//CEPC:Address-Line-3")
    end
    let(:cepc_address_line_four) do
      non_domestic_xml.at("//CEPC:Address-Line-4")
    end

    before do
      add_assessor(
        scheme_id,
        "SPEC000000",
        AssessorStub.new.fetch_request_body(
          nonDomesticNos3: "ACTIVE",
          nonDomesticNos4: "ACTIVE",
          nonDomesticNos5: "ACTIVE",
          nonDomesticDec: "ACTIVE",
          domesticRdSap: "ACTIVE",
          domesticSap: "ACTIVE",
          nonDomesticSp3: "ACTIVE",
          nonDomesticCc4: "ACTIVE",
          gda: "ACTIVE",
        ),
      )

      expired_assessment.at("UPRN").remove

      lodge_assessment(
        assessment_body: expired_assessment.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      assessment_id.children = "0000-0000-0000-0000-0001"
      address_line_one.children = "2 Other Street"

      lodge_assessment(
        assessment_body: assessment.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      cepc_assessment_id.children = "0000-0000-0000-0000-0002"
      cepc_address_line_one.children = "3 Other Street"
      cepc_address_line_two.children = ""
      cepc_address_line_three.children = ""
      cepc_address_line_four.children = ""

      lodge_assessment(
        assessment_body: non_domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )

      assessment_id.children = "0000-0000-0000-0000-0003"
      address_line_one.children = "The House"
      address_line_two.content = "123 Test Street"
      address_line_one.add_next_sibling address_line_two

      lodge_assessment(
        assessment_body: assessment.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      assessment_id.children = "0000-0000-0000-0000-0004"
      address_line_one.children = "3 Other Street"
      address_line_two.content = nil
      address_line_one.add_next_sibling address_line_two
      town.children = "Some County"

      lodge_assessment(
        assessment_body: assessment.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      assessment_id.children = "0000-0000-0000-0000-0005"
      address_id.children = "RRN-0000-0000-0000-0000-0000"
      address_line_two.content = nil
      address_line_one.add_next_sibling address_line_two
      assessment_date.children = Date.today.prev_day.strftime("%Y-%m-%d")

      lodge_assessment(
        assessment_body: assessment.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )
    end

    describe "searching by street and town" do
      context "when a lodgement has a legacy address id" do
        before do
          lodge_assessment(
            assessment_body: Samples.xml("CEPC-7.0", "dec"),
            accepted_responses: [201],
            scopes: %w[assessment:lodge migrate:assessment],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            schema_name: "CEPC-7.0",
            override: true,
            migrated: true,
            ensure_uprns: false,
          )
        end

        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?street=Lonely%20Street&town=Whitbury",
              [200],
              true,
              {},
              %w[address:search],
            ).body,
            symbolize_names: true,
          )
        end

        it "does not return an LPRN address id in the results" do
          address_ids = response[:data][:addresses].map { |a| a[:addressId] }

          expect(address_ids).not_to include "LPRN-000000000001"
        end
      end

      context "when street is missing some letters" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?street=Some%20Stre&town=Whitbury",
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
              addressId: "RRN-0000-0000-0000-0000-0000",
              line1: "1 Some Street",
              line2: nil,
              line3: nil,
              line4: nil,
              town: "Whitbury",
              postcode: "A0 0AA",
              source: "PREVIOUS_ASSESSMENT",
              existingAssessments: [
                {
                  assessmentId: "0000-0000-0000-0000-0000",
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
              "/api/search/addresses?street=Some%20Street&town=Whitbury",
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
              addressId: "RRN-0000-0000-0000-0000-0000",
              line1: "1 Some Street",
              line2: nil,
              line3: nil,
              line4: nil,
              town: "Whitbury",
              postcode: "A0 0AA",
              source: "PREVIOUS_ASSESSMENT",
              existingAssessments: [
                {
                  assessmentId: "0000-0000-0000-0000-0000",
                  assessmentStatus: "ENTERED",
                  assessmentType: "RdSAP",
                },
              ],
            },
          )
        end
      end

      context "with a cancelled assessment" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?street=Some%20Street&town=Whitbury",
              [200],
              true,
              {},
              %w[address:search],
            ).body,
            symbolize_names: true,
          )
        end

        before do
          update_assessment_status(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_status_body: {
              status: "CANCELLED",
            },
            auth_data: {
              scheme_ids: [scheme_id],
            },
            accepted_responses: [200],
          )
        end

        it "returns the address" do
          expect(response[:data][:addresses].length).to eq 1
        end

        it "does not include the assessment in existing assessments" do
          expect(
            response[:data][:addresses][0][:existingAssessments],
          ).to be_empty
        end
      end

      context "with a not-for-issue assessment" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?street=Some%20Street&town=Whitbury",
              [200],
              true,
              {},
              %w[address:search],
            ).body,
            symbolize_names: true,
          )
        end

        before do
          update_assessment_status(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_status_body: {
              status: "NOT_FOR_ISSUE",
            },
            auth_data: {
              scheme_ids: [scheme_id],
            },
            accepted_responses: [200],
          )
        end

        it "returns the address" do
          expect(response[:data][:addresses].length).to eq 1
        end

        it "does not include the assessment in existing assessments" do
          expect(
            response[:data][:addresses][0][:existingAssessments],
          ).to be_empty
        end
      end

      context "with an entered assessment" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?street=Some%20Street&town=Whitbury",
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
              addressId: "RRN-0000-0000-0000-0000-0000",
              line1: "1 Some Street",
              line2: nil,
              line3: nil,
              line4: nil,
              town: "Whitbury",
              postcode: "A0 0AA",
              source: "PREVIOUS_ASSESSMENT",
              existingAssessments: [
                {
                  assessmentId: "0000-0000-0000-0000-0000",
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
                "/api/search/addresses?street=Some%20Street&town=Whitbury",
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
                addressId: "RRN-0000-0000-0000-0000-0000",
                line1: "1 Some Street",
                line2: nil,
                line3: nil,
                line4: nil,
                town: "Whitbury",
                postcode: "A0 0AA",
                source: "PREVIOUS_ASSESSMENT",
                existingAssessments: [
                  {
                    assessmentId: "0000-0000-0000-0000-0000",
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
              "/api/search/addresses?street=Some%20Street&town=Whitbury&addressType=DOMESTIC",
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
              addressId: "RRN-0000-0000-0000-0000-0000",
              line1: "1 Some Street",
              line2: nil,
              line3: nil,
              line4: nil,
              town: "Whitbury",
              postcode: "A0 0AA",
              source: "PREVIOUS_ASSESSMENT",
              existingAssessments: [
                {
                  assessmentId: "0000-0000-0000-0000-0000",
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
            "/api/search/addresses?street=Other%20Street&town=Whitbury&addressType=asdf",
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
              "/api/search/addresses?street=Other%20Street&town=Whitbury&addressType=COMMERCIAL",
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
              addressId: "UPRN-000000000001",
              line1: "3 Other Street",
              line2: nil,
              line3: nil,
              line4: nil,
              town: "Whitbury",
              postcode: "A0 0AA",
              source: "GAZETTEER",
              existingAssessments: [
                {
                  assessmentId: "0000-0000-0000-0000-0002",
                  assessmentStatus: "ENTERED",
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
              "/api/search/addresses?street=Test%20Street&town=Whitbury",
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
              addressId: "UPRN-000000000000",
              line1: "The House",
              line2: "123 Test Street",
              line3: nil,
              line4: nil,
              town: "Whitbury",
              postcode: "A0 0AA",
              source: "GAZETTEER",
              existingAssessments: [
                {
                  assessmentId: "0000-0000-0000-0000-0003",
                  assessmentStatus: "ENTERED",
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
