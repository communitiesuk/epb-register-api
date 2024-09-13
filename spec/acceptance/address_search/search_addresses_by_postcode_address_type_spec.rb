describe "Acceptance::AddressSearch::ByPostcode::WithAddressType", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  let(:scheme_id) { add_scheme_and_get_id }

  let(:domestic_xml) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }

  let(:non_domestic_xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc") }
  let(:non_domestic_assessment_id) { non_domestic_xml.at("//CEPC:RRN") }

  before do
    insert_into_address_base("73546792", "SW1A 2AA", "5 Grimal Place", "Skewit Road", "London", "E")
    insert_into_address_base("73546793", "SW1A 2AA", "The house Grimal Place", "Skewit Road", "London", "E")
    insert_into_address_base("73546795", "SW1A 2AA", "2 Grimal Place", "345 Skewit Road", "London", "E")
    insert_into_address_base("736042792", "NE23 1TW", "5 Grimiss Place", "Suggton Road", "Newcastle", "E")
    add_super_assessor(scheme_id:)

    domestic_xml.at("UPRN").remove

    lodge_assessment(
      assessment_body: domestic_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      override: true,
    )

    non_domestic_assessment_id.children = "0000-0000-0000-0000-0002"
    non_domestic_xml.at("//*[local-name() = 'UPRN']").remove
    lodge_assessment(
      assessment_body: non_domestic_xml.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      schema_name: "CEPC-8.0.0",
    )
  end

  describe "searching by postcode" do
    context "when an invalid address type is provided" do
      it "returns status 422" do
        expect(assertive_get(
          "/api/search/addresses?postcode=SW1A%202AA&addressType=asdf",
          accepted_responses: [422],
          scopes: %w[address:search],
        ).status).to eq(422)
      end
    end

    context "when an address type of domestic is provided" do
      let(:response) do
        JSON.parse(
          assertive_get(
            "/api/search/addresses?postcode=SW1A%202AA&addressType=DOMESTIC",
            scopes: %w[address:search],
          ).body,
          symbolize_names: true,
        )
      end

      it "returns the expected amount of addresses" do
        expect(response[:data][:addresses].length).to eq 4
      end

      it "returns the address from address_base" do
        expect(response[:data][:addresses][2]).to eq(
          {
            line1: "5 Grimal Place",
            line2: "Skewit Road",
            line3: nil,
            line4: nil,
            postcode: "SW1A 2AA",
            town: "London",
            addressId: "UPRN-000073546792",
            source: "GAZETTEER",
            existingAssessments: [],
          },
        )
      end

      it "returns the expected previous assessment address" do
        expect(response[:data][:addresses][0]).to eq(
          {
            addressId: "RRN-0000-0000-0000-0000-0000",
            line1: "1 Some Street",
            line2: nil,
            line3: nil,
            line4: nil,
            town: "Whitbury",
            postcode: "SW1A 2AA",
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

    context "when an address type of non-domestic is provided" do
      let(:response) do
        JSON.parse(
          assertive_get(
            "/api/search/addresses?postcode=SW1A%202AA&addressType=COMMERCIAL",
            accepted_responses: [200],
            scopes: %w[address:search],
          ).body,
          symbolize_names: true,
        )
      end

      it "returns the expected amount of addresses" do
        expect(response[:data][:addresses].length).to eq 4
      end

      it "returns the address from address base" do
        expect(response[:data][:addresses][1]).to eq(
          {
            line1: "5 Grimal Place",
            line2: "Skewit Road",
            line3: nil,
            line4: nil,
            postcode: "SW1A 2AA",
            town: "London",
            addressId: "UPRN-000073546792",
            source: "GAZETTEER",
            existingAssessments: [],
          },
        )
      end

      it "returns the expected previous assessment address" do
        expect(response[:data][:addresses][2]).to eq(
          {
            addressId: "RRN-0000-0000-0000-0000-0002",
            line1: "Some Unit",
            line2: "2 Lonely Street",
            line3: "Some Area",
            line4: "Some County",
            town: "Whitbury",
            postcode: "SW1A 2AA",
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
end
