describe Gateway::HomeEnergyRetrofitAdviceGateway do
  include RSpecRegisterApiServiceMixin

  subject(:gateway) { described_class.new }

  let(:scheme_id) { add_scheme_and_get_id }

  let(:rdsap_xml) { Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0") }

  context "when expecting to find an RdSAP assessment" do
    before do
      add_super_assessor(scheme_id: scheme_id)

      lodge_assessment(
        assessment_body: rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
        )
    end

    expected_hera_details_hash = {
      type_of_assessment: "SAP",
      assessment_id: "0000-0000-0000-0000-0000",
      date_of_registration: "2020-05-04",
      address: {
        address_line1: "1 Some Street",
        address_line2: "Some Area",
        address_line3: "Some County",
        address_line4: nil,
        town: "Whitbury",
        postcode: "A0 0AA",
      },
      dwelling_type: "Mid-terrace house",
      built_form: "1",
      main_dwelling_construction_age_band_or_year: "1750",
      property_summary: [
        {
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "walls",
          description: "Brick walls",
        },
        {
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "walls",
          description: "Brick walls",
        },
        {
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "roof",
          description: "Slate roof",
        },
        {
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "roof",
          description: "slate roof",
        },
        {
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "floor",
          description: "Tiled floor",
        },
        {
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "floor",
          description: "Tiled floor",
        },
        {
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "windows",
          description: "Glass window",
        },
        {
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "main_heating",
          description: "Gas boiler",
        },
        {
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "main_heating",
          description: "Gas boiler",
        },
        {
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "main_heating_controls",
          description: "Thermostat",
        },
        {
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "main_heating_controls",
          description: "Thermostat",
        },
        {
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "secondary_heating",
          description: "Electric heater",
        },
        {
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "hot_water",
          description: "Gas boiler",
        },
        {
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "lighting",
          description: "Energy saving bulbs",
        },
        {
          energy_efficiency_rating: 0,
          environmental_efficiency_rating: 0,
          name: "air_tightness",
          description: "Draft Exclusion",
        },
      ],
      main_heating_category: "1",
      main_fuel_type: "36",
      has_hot_water_cylinder: "true",
    }


    context "when fetching by RRN" do
      xit "finds and returns the expected data when one match exists", aggregate_failures: true do
        result = gateway.fetch_by_rrn("0000-0000-0000-0000-0000")

        expect(result).to be_a(Domain::AssessmentHeraDetails)
        expect(result.to_hash).to eq expected_hera_details_hash
      end

      xit "returns nil when no match" do
        expect(gateway.search_by_rrn("0000-1111-2222-3333-4444")).to be_nil
      end

      context "with a RRN that has been previously cancelled" do
        before do
          update_assessment_status(
            assessment_id: "0000-0000-0000-0000-0000",
            assessment_status_body: {
              "status": "CANCELLED",
            },
            accepted_responses: [200],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            )
        end

        it "returns nil" do
          expect(gateway.search_by_rrn("0000-0000-0000-0000-0000")).to be_nil
        end
      end
    end
  end
end
