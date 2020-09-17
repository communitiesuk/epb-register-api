describe "Acceptance::AddressSearch::ByPostcode" do
  include RSpecRegisterApiServiceMixin

  context "an address that has a report lodged" do
    let(:scheme_id) { add_scheme_and_get_id }

    let(:doc) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }
    let(:expired_assessment) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }
    let(:address_id) { doc.at("UPRN") }
    let(:assessment_id) { doc.at("RRN") }
    let(:assessment_date) { doc.at("Registration-Date") }
    let(:address_line_one) { doc.search("Address-Line-1")[1] }
    let(:address_line_two) { Nokogiri::XML::Node.new "Address-Line-2", doc }

    let(:non_domestic_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc") }
    let(:cepc_scheme_assessor_id) do
      non_domestic_xml.at("//CEPC:Certificate-Number")
    end
    let(:cepc_assessment_id) { non_domestic_xml.at("//CEPC:RRN") }
    let(:cepc_assessment_date) { non_domestic_xml.at("//CEPC:Inspection-Date") }
    let(:cepc_address_line_one) { non_domestic_xml.at("//CEPC:Address-Line-1") }

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
      expired_assessment.at("UPRN").remove

      lodge_assessment(
        assessment_body: expired_assessment.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        override: true,
      )

      assessment_id.children = "0000-0000-0000-0000-0001"
      address_id.children = "RRN-0000-0000-0000-0000-0000"
      address_line_one.children = "2 Some Street"
      assessment_date.children = Date.today.prev_day(3).strftime("%Y-%m-%d")

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        override: true,
      )

      cepc_assessment_id.children = "0000-0000-0000-0000-0002"
      cepc_address_line_one.children = "3 Other Street"
      cepc_scheme_assessor_id.children = "SPEC000000"
      cepc_assessment_date.children =
        Date.today.prev_day(2).strftime("%Y-%m-%d")

      lodge_assessment(
        assessment_body: non_domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: "CEPC-8.0.0",
      )

      assessment_id.children = "0000-0000-0000-0000-0003"
      address_id.children = "RRN-0000-0000-0000-0000-0003"
      address_line_one.children = "The House"
      address_line_two.content = "123 Test Street"
      address_line_one.add_next_sibling address_line_two
      assessment_date.children = Date.today.prev_year(11).strftime("%Y-%m-%d")

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        override: true,
      )

      assessment_id.children = "0000-0000-0000-0000-0004"
      address_id.children = "RRN-0000-0000-0000-0000-0003"
      assessment_date.children = Date.today.strftime("%Y-%m-%d")

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        override: true,
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
              ).body,
              symbolize_names: true,
            )
          end

          it "returns the expected amount of addresses" do
            expect(response[:data][:addresses].length).to eq 7
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
            expect(response[:data][:addresses][5]).to eq(
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
                    assessmentStatus: "ENTERED",
                    assessmentType: "CEPC",
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
              ).body,
              symbolize_names: true,
            )
          end

          it "returns the expected amount of addresses" do
            expect(response[:data][:addresses].length).to eq 7
          end

          it "returns the expected address" do
            expect(response[:data][:addresses][5]).to eq(
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
                    assessmentStatus: "ENTERED",
                    assessmentType: "CEPC",
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
          expect(response[:data][:addresses].length).to eq 7
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
                {
                  assessmentId: "0000-0000-0000-0000-0001",
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
          expect(response[:data][:addresses].length).to eq 7
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
                {
                  assessmentId: "0000-0000-0000-0000-0001",
                  assessmentStatus: "ENTERED",
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
              ).body,
              symbolize_names: true,
            )
          end

          it "returns the expected amount of addresses" do
            expect(response[:data][:addresses].length).to eq 7
          end

          it "returns the address from address_base" do
            expect(response[:data][:addresses][0]).to eq(
              {
                line1: "The house Grimal Place",
                line2: "Skewit Road",
                line3: nil,
                line4: nil,
                postcode: "A0 0AA",
                town: "London",
                addressId: "UPRN-000073546793",
                source: "GAZETTEER",
                existingAssessments: [],
              },
            )
          end

          it "returns the expected previous assessment address" do
            expect(response[:data][:addresses][3]).to eq(
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
                  {
                    assessmentId: "0000-0000-0000-0000-0004",
                    assessmentStatus: "ENTERED",
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
              ).body,
              symbolize_names: true,
            )
          end

          it "returns the expected amount of addresses" do
            expect(response[:data][:addresses].length).to eq 7
          end

          it "returns the address from address_base" do
            expect(response[:data][:addresses][0]).to eq(
              {
                line1: "2 Grimal Place",
                line2: "345 Skewit Road",
                line3: nil,
                line4: nil,
                postcode: "A0 0AA",
                town: "London",
                addressId: "UPRN-000073546795",
                source: "GAZETTEER",
                existingAssessments: [],
              },
            )
          end

          it "returns the expected previous assessment address" do
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
                  {
                    assessmentId: "0000-0000-0000-0000-0001",
                    assessmentStatus: "ENTERED",
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
              ).body,
              symbolize_names: true,
            )
          end

          it "returns the expected amount of addresses" do
            expect(response[:data][:addresses].length).to eq 7
          end

          it "returns the address from address_base" do
            expect(response[:data][:addresses][2]).to eq(
              {
                line1: "2 Grimal Place",
                line2: "345 Skewit Road",
                line3: nil,
                line4: nil,
                postcode: "A0 0AA",
                town: "London",
                addressId: "UPRN-000073546795",
                source: "GAZETTEER",
                existingAssessments: [],
              },
            )
          end

          it "returns the expected previous assessment address" do
            expect(response[:data][:addresses][4]).to eq(
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
                    assessmentStatus: "ENTERED",
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
            ).body,
            symbolize_names: true,
          )
        end

        it "returns the expected amount of addresses" do
          expect(response[:data][:addresses].length).to eq 6
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

        it "returns the expected previous assessment address" do
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
                {
                  assessmentId: "0000-0000-0000-0000-0001",
                  assessmentStatus: "ENTERED",
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
            ).body,
            symbolize_names: true,
          )
        end

        it "returns the expected amount of addresses" do
          expect(response[:data][:addresses].length).to eq 4
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

        it "returns the expected previous assessment address" do
          expect(response[:data][:addresses][3]).to eq(
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
                  assessmentStatus: "ENTERED",
                  assessmentType: "CEPC",
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
              "/api/search/addresses?postcode=A0%200AA",
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
            assessment_id: "0000-0000-0000-0000-0001",
            assessment_status_body: { status: "CANCELLED" },
            auth_data: { scheme_ids: [scheme_id] },
            accepted_responses: [200],
          )
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

        it "returns the expected previous assessment address" do
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

      context "with a not for issue assessment" do
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

        before do
          update_assessment_status(
            assessment_id: "0000-0000-0000-0000-0001",
            assessment_status_body: { status: "NOT_FOR_ISSUE" },
            auth_data: { scheme_ids: [scheme_id] },
            accepted_responses: [200],
          )
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

        it "returns the expected previous assessment address" do
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
