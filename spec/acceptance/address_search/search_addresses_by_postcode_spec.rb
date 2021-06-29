describe "Acceptance::AddressSearch::ByPostcode", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  context "when there are existing assessments at a postcode" do
    let(:scheme_id) { add_scheme_and_get_id }

    let(:rdsap_schema) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }

    let(:non_domestic_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc") }
    let(:cepc_assessment_id) { non_domestic_xml.at("//CEPC:RRN") }

    before do
      ActiveRecord::Base.connection.exec_query(
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
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
      )

      cepc_assessment_id.children = "0000-0000-0000-0000-0002"
      lodge_assessment(
        assessment_body: non_domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )
    end

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

    context "when a postcode is less than 3 characters long is provided" do
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
      context "when there are entered assessments" do
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

        it "returns the expected address entries" do
          address_ids =
            response[:data][:addresses].map { |address| address[:addressId] }

          expect(address_ids).to eq %w[
            UPRN-000000000000
            UPRN-000073546795
            UPRN-000073546792
            UPRN-000000000001
            UPRN-000073546793
          ]
        end

        it "returns the expected address entry for an existing assessment" do
          expect(response[:data][:addresses][0]).to eq(
            {
              addressId: "UPRN-000000000000",
              line1: "1 Some Street",
              line2: nil,
              line3: nil,
              line4: nil,
              town: "Whitbury",
              postcode: "A0 0AA",
              source: "GAZETTEER",
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

      context "when two lodgements have the same address but with different cases" do
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
          rdsap_schema.at("RRN").content = "0000-1111-2222-3333-4444"
          rdsap_schema.at("Address/Address-Line-1").content = "1 SOME STREET"
          rdsap_schema.at("UPRN").remove

          lodge_assessment(
            assessment_body: rdsap_schema.to_xml,
            accepted_responses: [201],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            override: true,
          )
        end

        it "does not return duplicates of the address" do
          address_ids = response[:data][:addresses].map { |a| a[:addressId] }

          expect(address_ids).not_to include "RRN-0000-1111-2222-3333-4444"
        end
      end

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
          )
        end

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

        it "does not return an LPRN address id in the results" do
          address_ids = response[:data][:addresses].map { |a| a[:addressId] }

          expect(address_ids).not_to include "LPRN-000000000001"
        end
      end

      context "when both parts of dual lodgement expire at the same time" do
        let(:dual_lodgement) do
          xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "ac-cert+ac-report")
          xml
            .xpath("//*[local-name() = 'RRN']")
            .each_with_index do |node, index|
              node.content = "1111-0000-0000-0000-000#{index}"
            end

          xml
            .xpath("//*[local-name() = 'Related-RRN']")
            .reverse
            .each_with_index do |node, index|
              node.content = "1111-0000-0000-0000-000#{index}"
            end

          xml
        end

        context "when using an existing UPRN as the address id" do
          before do
            dual_lodgement
              .xpath("//*[local-name() = 'UPRN']")
              .each { |node| node.content = "UPRN-000073546792" }

            lodge_assessment(
              assessment_body: dual_lodgement.to_xml,
              accepted_responses: [201],
              auth_data: {
                scheme_ids: [scheme_id],
              },
              schema_name: "CEPC-8.0.0",
            )
          end

          let(:response) do
            JSON.parse assertive_get(
              "/api/search/addresses?postcode=A0+0AA&address_type=COMMERCIAL",
              [200],
              true,
              {},
              %w[address:search],
            ).body,
                       symbolize_names: true
          end

          it "includes both assessments in the existing assessments for the address" do
            entry =
              response[:data][:addresses].select { |address|
                address[:addressId] == "UPRN-000073546792"
              }.first

            expect(entry[:existingAssessments]).to eq [
              {
                assessmentId: "1111-0000-0000-0000-0000",
                assessmentStatus: "ENTERED",
                assessmentType: "AC-CERT",
              },
              {
                assessmentId: "1111-0000-0000-0000-0001",
                assessmentStatus: "ENTERED",
                assessmentType: "AC-REPORT",
              },
            ]
          end
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

      it "returns the expected address base entries" do
        address_ids =
          response[:data][:addresses].map { |address| address[:addressId] }

        expect(address_ids).to eq %w[
          UPRN-000000000000
          UPRN-000073546795
          UPRN-000073546792
          UPRN-000000000001
          UPRN-000073546793
        ]
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

      it "returns the expected address base entries" do
        address_ids =
          response[:data][:addresses].map { |address| address[:addressId] }
        expect(address_ids).to eq %w[
          UPRN-000000000000
          UPRN-000073546795
          UPRN-000073546792
          UPRN-000000000001
          UPRN-000073546793
        ]
      end

      it "returns the expected address entry for an existing assessment" do
        expect(response[:data][:addresses][0]).to eq(
          {
            addressId: "UPRN-000000000000",
            line1: "1 Some Street",
            line2: nil,
            line3: nil,
            line4: nil,
            town: "Whitbury",
            postcode: "A0 0AA",
            source: "GAZETTEER",
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
