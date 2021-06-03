require_relative "xml_view_test_helper"

describe ViewModel::CepcWrapper do
  context "when calling to_hash" do
    let(:schemas) do
      [
        {
          schema: "CEPC-8.0.0",
          type: "cepc",
          different_buried_fields: {
            address: {
              address_id: "UPRN-000000000001",
            },
          },
        },
        {
          schema: "CEPC-NI-8.0.0",
          type: "cepc",
          different_buried_fields: {
            address: {
              address_id: "UPRN-000000000001",
            },
          },
        },
        { schema: "CEPC-7.1", type: "cepc" },
        {
          schema: "CEPC-7.0",
          type: "cepc",
          unsupported_fields: %i[primary_energy_use],
        },
        {
          schema: "CEPC-6.0",
          type: "cepc",
          unsupported_fields: %i[primary_energy_use],
        },
        {
          schema: "CEPC-5.1",
          type: "cepc",
          unsupported_fields: %i[primary_energy_use],
        },
        {
          schema: "CEPC-5.0",
          type: "cepc",
          unsupported_fields: %i[primary_energy_use],
        },
        {
          schema: "CEPC-4.0",
          type: "cepc",
          unsupported_fields: %i[primary_energy_use building_emission_rate],
        },
        {
          schema: "CEPC-3.1",
          type: "cepc",
          unsupported_fields: %i[primary_energy_use building_emission_rate],
        },
      ]
    end

    let(:assertion) do
      {
        assessment_id: "0000-0000-0000-0000-0000",
        date_of_expiry: "2026-05-04",
        address: {
          address_id: "LPRN-000000000001",
          address_line1: "Some Unit",
          address_line2: "2 Lonely Street",
          address_line3: "Some Area",
          address_line4: "Some County",
          town: "Whitbury",
          postcode: "A0 0AA",
        },
        technical_information: {
          main_heating_fuel: "Natural Gas",
          building_environment: "Air Conditioning",
          floor_area: "403",
          building_level: "3",
        },
        building_emission_rate: "67.09",
        primary_energy_use: "413.22",
        new_build_rating: "28",
        new_build_band: "b",
        existing_build_rating: "81",
        existing_build_band: "d",
        energy_efficiency_rating: "80",
        assessor: {
          scheme_assessor_id: "SPEC000000",
          name: "TEST NAME BOI",
          company_details: {
            name: "Trillian Certificates Plc",
            address: "123 My Street, My City, AB3 4CD",
          },
          contact_details: {
            email: "a@b.c",
            telephone: "012345",
          },
        },
        report_type: "3",
        type_of_assessment: "CEPC",
        current_energy_efficiency_band: "d",
        date_of_assessment: "2020-05-04",
        date_of_registration: "2020-05-04",
        related_party_disclosure: "1",
        property_type: "B1 Offices and Workshop businesses",
      }
    end

    it "reads the appropriate values" do
      test_xml_doc(schemas, assertion)
    end
  end

  context "when calling to_report" do
    let(:schemas) do
      [
        { schema: "CEPC-8.0.0", type: "cepc" },
        { schema: "CEPC-NI-8.0.0", type: "cepc" },
        { schema: "CEPC-7.1", type: "cepc" },
        {
          schema: "CEPC-7.0",
          type: "cepc",
          unsupported_fields: %i[primary_energy_value],
        },
        {
          schema: "CEPC-6.0",
          type: "cepc",
          unsupported_fields: %i[primary_energy_value],
        },
        {
          schema: "CEPC-5.1",
          type: "cepc",
          unsupported_fields: %i[primary_energy_value],
        },
        {
          schema: "CEPC-5.0",
          type: "cepc",
          unsupported_fields: %i[primary_energy_value],
        },
        {
          schema: "CEPC-4.0",
          type: "cepc",
          unsupported_fields: %i[
            primary_energy_value
            transaction_type
            standard_emissions
            building_emissions
            target_emissions
            typical_emissions
          ],
        },
        {
          schema: "CEPC-3.1",
          type: "cepc",
          unsupported_fields: %i[
            primary_energy_value
            transaction_type
            standard_emissions
            building_emissions
            target_emissions
            typical_emissions
            aircon_kw_rating
            estimated_aircon_kw_rating
            ac_inspection_commissioned
          ],
        },
      ]
    end

    let(:assertion) do
      {
        assessment_id: "0000-0000-0000-0000-0000",
        address1: "Some Unit",
        address2: "2 Lonely Street",
        address3: "Some Area",
        posttown: "Whitbury",
        postcode: "A0 0AA",
        building_reference_number: "UPRN-000000000123",
        asset_rating: "80",
        asset_rating_band: "d",
        property_type: "B1 Offices and Workshop businesses",
        inspection_date: "2020-05-04",
        lodgement_date: "2020-05-04",
        transaction_type: "Mandatory issue (Marketed sale)",
        new_build_benchmark: "28",
        existing_stock_benchmark: "81",
        standard_emissions: "42.07",
        building_emissions: "67.09",
        main_heating_fuel: "Natural Gas",
        building_level: "3",
        floor_area: "403",
        other_fuel_desc: "Test",
        special_energy_uses: "Test sp",
        aircon_present: "N",
        aircon_kw_rating: "100",
        estimated_aircon_kw_rating: "3",
        ac_inspection_commissioned: "1",
        target_emissions: "23.2",
        typical_emissions: "67.98",
        building_environment: "Air Conditioning",
        primary_energy_value: "413.22",
        report_type: "3",
        renewable_sources: "Renewable sources test",
      }
    end

    let(:assessments_address_id_gateway) do
      instance_double(Gateway::AssessmentsAddressIdGateway)
    end

    before do
      allow(Gateway::AssessmentsAddressIdGateway).to receive(:new).and_return(
        assessments_address_id_gateway,
      )
      allow(assessments_address_id_gateway).to receive(:fetch)
        .with("0000-0000-0000-0000-0000")
        .and_return(
          {
            assessment_id: "0000-0000-0000-0000-0000",
            address_id: "UPRN-000000000123",
            source: "lodgment",
          },
        )
    end

    it "reads the appropriate values" do
      test_xml_doc(schemas, assertion, :to_report)
    end
  end

  it "returns the expect error without a valid schema type" do
    expect { ViewModel::CepcWrapper.new "", "invalid" }.to raise_error(
      ArgumentError,
    ).with_message "Unsupported schema type"
  end
end
