describe "Acceptance::AddressSearch::ByPostcode::AdditionalParams", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:scheme_id) { add_scheme_and_get_id }

  let(:domestic_xml) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }
  let(:domestic_xml_assessment_id) { domestic_xml.at("RRN") }
  let(:domestic_xml_address_id) { domestic_xml.at("UPRN") }
  let(:domestic_xml_address_line_one) do
    domestic_xml.search("Address-Line-1")[1]
  end

  let(:non_domestic_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc") }
  let(:non_domestic_assessment_id) { non_domestic_xml.at("//CEPC:RRN") }

  before(:each) do
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
                'Skewit Road',
                '',
                '',
                'London'
              ),
              (
                '73546595',
                'A0 0AA',
                'The Cottage',
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
      assessment_body: domestic_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
    )

    non_domestic_assessment_id.children = "0000-0000-0000-0000-0002"
    lodge_assessment(
      assessment_body: non_domestic_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      schema_name: "CEPC-8.0.0",
    )

    domestic_xml_assessment_id.children = "0000-0000-0000-0000-0003"
    domestic_xml_address_id.children = "RRN-0000-0000-0000-0000-0003"
    domestic_xml_address_line_one.children = "The House"
    lodge_assessment(
      assessment_body: domestic_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
    )
  end

  describe "searching by postcode" do
    context "with slightly misspelled building name param" do
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

      it "returns the most relevant entries near the top" do
        address_line1 =
          response[:data][:addresses].map { |address| address[:line1] }

        expect(address_line1).to eq [
          "The House",
          "The house Grimal Place",
          "The Cottage",
          "Some Unit",
          "1 Some Street",
          "2 Grimal Place",
          "5 Grimal Place",
        ]
      end

      it "returns the expected previous assessment address entry" do
        address_ids =
          response[:data][:addresses].map { |address| address[:addressId] }

        expect(address_ids).to include "RRN-0000-0000-0000-0000-0003"
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

      it "returns the most relevant entries near the top" do
        address_line1 =
          response[:data][:addresses].map { |address| address[:line1] }

        expect(address_line1).to eq [
          "2 Grimal Place",
          "Some Unit",
          "1 Some Street",
          "5 Grimal Place",
          "The Cottage",
          "The House",
          "The house Grimal Place",
        ]
      end

      it "returns the expected previous assessment address entry" do
        address_ids =
          response[:data][:addresses].map { |address| address[:addressId] }

        expect(address_ids).to include "RRN-0000-0000-0000-0000-0003"
      end
    end

    describe "with a building number on address line 2" do
      let(:response) do
        JSON.parse(
          assertive_get(
            "/api/search/addresses?postcode=A0%200AA&buildingNameNumber=345",
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

      it "returns the most relevant entries near the top" do
        address_line1 =
          response[:data][:addresses].map { |address| address[:line1] }

        expect(address_line1).to eq [
          "The Cottage",
          "5 Grimal Place",
          "1 Some Street",
          "2 Grimal Place",
          "Some Unit",
          "The House",
          "The house Grimal Place",
        ]
      end

      it "returns the expected previous assessment address entry" do
        address_ids =
          response[:data][:addresses].map { |address| address[:addressId] }

        expect(address_ids).to include "RRN-0000-0000-0000-0000-0003"
      end
    end
  end
end
