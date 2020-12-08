describe "Acceptance::AddressSearch::ByPostcode" do
  include RSpecRegisterApiServiceMixin

  context "an address that has a report lodged" do
    let(:scheme_id) { add_scheme_and_get_id }

    let(:rdsap_schema) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }

    let(:non_domestic_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc") }
    let(:cepc_assessment_id) { non_domestic_xml.at("//CEPC:RRN") }

    before(:each) do
      ActiveRecord::Base.connection.execute(
        "INSERT INTO
              address_base
                (
                  uprn,
                  postcode,
                  address_line1,
                  address_line2,
                  address_line3,
                  address_line4,
                  town
                )
            VALUES
              (
                '73546792',
                'A0 0AA',
                '5 Grimal Place',
                'Skewit Road',
                '',
                '',
                'London'
              ),
              (
                '73546793',
                'A0 0AA',
                'The house Grimal Place',
                'Skewit Road',
                '',
                '',
                'London'
              ),
              (
                '73546795',
                'A0 0AA',
                '2 Grimal Place',
                '345 Skewit Road',
                '',
                '',
                'London'
              ),
              (
                '736042792',
                'NE23 1TW',
                '5 Grimiss Place',
                'Suggton Road',
                '',
                '',
                'Newcastle'
              )",
      )

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

      lodge_assessment(
        assessment_body: rdsap_schema.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        override: true,
      )

      cepc_assessment_id.children = "0000-0000-0000-0000-0002"
      lodge_assessment(
        assessment_body: non_domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )
    end

    describe "searching by postcode" do
      context "when an invalid postcode is provided" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?postcode=EH353NDMD",
              [200],
              true,
              {},
              %w[address:search],
            ).body,
            symbolize_names: true,
          )
        end

        it "returns no addresses" do
          expect(response[:data][:addresses].length).to eq 0
        end
      end

      context "when a postcode is less than 3 characters long" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?postcode=HA",
              [422],
              true,
              {},
              %w[address:search],
            ).body,
            symbolize_names: true,
          )
        end

        it "returns the expected error response" do
          expect(response[:errors]).to eq(
            [
              {
                code: "INVALID_REQUEST",
                title:
                  "The property '#/' of type object did not match any of the required schemas",
              },
            ],
          )
        end
      end

      context "when a valid postcode is provided" do
        context "with an entered assessment" do
          let(:response) do
            JSON.parse(
              assertive_get(
                "/api/search/addresses?postcode=A0%200AA",
                [200],
                true,
                {},
                %w[address:search],
              ).body,
              symbolize_names: true,
            )
          end

          it "returns the expected amount of addresses" do
            expect(response[:data][:addresses].length).to eq 5
          end

          it "returns the address from address_base" do
            expect(response[:data][:addresses][0]).to eq(
              {
                line1: "5 Grimal Place",
                line2: "Skewit Road",
                line3: nil,
                line4: nil,
                postcode: "A0 0AA",
                town: "London",
                addressId: "UPRN-000073546792",
                source: "GAZETTEER",
                existingAssessments: [],
              },
            )
          end

          it "returns the expected address" do
            expect(response[:data][:addresses][3]).to eq(
              {
                addressId: "RRN-0000-0000-0000-0000-0000",
                line1: "1 Some Street",
                line2: nil,
                line3: nil,
                line4: nil,
                town: "Post-Town1",
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

      context "when there is no space in the postcode" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?postcode=A00AA",
              [200],
              true,
              {},
              %w[address:search],
            ).body,
            symbolize_names: true,
          )
        end

        it "returns the expected amount of addresses" do
          expect(response[:data][:addresses].length).to eq 5
        end

        it "returns the address from address_base" do
          expect(response[:data][:addresses][0]).to eq(
            {
              line1: "5 Grimal Place",
              line2: "Skewit Road",
              line3: nil,
              line4: nil,
              postcode: "A0 0AA",
              town: "London",
              addressId: "UPRN-000073546792",
              source: "GAZETTEER",
              existingAssessments: [],
            },
          )
        end

        it "returns the address from previous assessments" do
          expect(response[:data][:addresses][3]).to eq(
            {
              addressId: "RRN-0000-0000-0000-0000-0000",
              line1: "1 Some Street",
              line2: nil,
              line3: nil,
              line4: nil,
              town: "Post-Town1",
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

      context "when the input postcode is not in the same case as the recorded postcode" do
        let(:response) do
          JSON.parse(
            assertive_get(
              "/api/search/addresses?postcode=a00aa",
              [200],
              true,
              {},
              %w[address:search],
            ).body,
            symbolize_names: true,
          )
        end

        it "returns the expected amount of addresses" do
          expect(response[:data][:addresses].length).to eq 5
        end

        it "returns the address from address_base" do
          expect(response[:data][:addresses][0]).to eq(
            {
              line1: "5 Grimal Place",
              line2: "Skewit Road",
              line3: nil,
              line4: nil,
              postcode: "A0 0AA",
              town: "London",
              addressId: "UPRN-000073546792",
              source: "GAZETTEER",
              existingAssessments: [],
            },
          )
        end

        it "returns the address from previous assessments" do
          expect(response[:data][:addresses][3]).to eq(
            {
              addressId: "RRN-0000-0000-0000-0000-0000",
              line1: "1 Some Street",
              line2: nil,
              line3: nil,
              line4: nil,
              town: "Post-Town1",
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
  end
end
