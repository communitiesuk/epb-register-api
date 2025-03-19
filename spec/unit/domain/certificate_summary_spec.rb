describe Domain::CertificateSummary do
  let(:assessment) do
    {
      "created_at" => Time.utc(2021, 2, 22),
      "opt_out" => false,
      "cancelled_at" => nil,
      "not_for_issue_at" => nil,
      "assessment_address_id" => "UPRN-000000000000",
      "country_name" => "England",
      "scheme_assessor_id" => "SPEC000000",
      "assessor_first_name" => "Someone",
      "assessor_last_name" => "Person",
      "assessor_telephone_number" => "010199991010101",
      "assessor_email" => "person@person.com",
      "scheme_id" => 1,
      "scheme_name" => "test scheme",
      "schema_type" => "RdSAP-Schema-20.0.0",
      "xml" => xml_fixture,
      "green_deal_plan_id" => nil,
      "count_address_id_assessments" => 2,
    }
  end
  let(:xml_fixture) do
    Samples.xml "RdSAP-Schema-20.0.0"
  end
  let(:assessment_id) { "0000-0000-0000-0000-0000" }

  let(:expected_view_model_data) do
    {
      "type_of_assessment": "RdSAP",
      "assessment_id": "0000-0000-0000-0000-0000",
      "date_of_expiry": "2030-05-03",
      "date_of_assessment": "2020-05-04",
      "date_of_registration": "2020-05-04",
      "address": {
        "address_line1": "1 Some Street",
        "address_line2": "",
        "address_line3": "",
        "address_line4": nil,
        "town": "Whitbury",
        "postcode": "SW1A 2AA",
      },
      "assessor": {
        "scheme_assessor_id": "SPEC000000",
        "name": "Testa Sessor",
        "contact_details": {
          "email": "a@b.c",
          "telephone": "0555 497 2848",
        },
      },
      "current_carbon_emission": 2.4,
      "current_energy_efficiency_band": "e",
      "current_energy_efficiency_rating": 50,
      "dwelling_type": "Mid-terrace house",
      "estimated_energy_cost": "689.83",
      "heat_demand": {
        "current_space_heating_demand": 13_120,
        "current_water_heating_demand": 2285,
      },
      "heating_cost_current": "365.98",
      "heating_cost_potential": "250.34",
      "hot_water_cost_current": "200.40",
      "hot_water_cost_potential": "180.43",
      "lighting_cost_current": "123.45",
      "lighting_cost_potential": "84.23",
      "potential_carbon_emission": 1.4,
      "potential_energy_efficiency_band": "c",
      "potential_energy_efficiency_rating": 72,
      "potential_energy_saving": "174.83",
      "property_summary": [
        {
          "energy_efficiency_rating": 1,
          "environmental_efficiency_rating": 1,
          "name": "wall",
          "description": "Solid brick, as built, no insulation (assumed)",
        },
        {
          "energy_efficiency_rating": 4,
          "environmental_efficiency_rating": 4,
          "name": "wall",
          "description": "Cavity wall, as built, insulated (assumed)",
        },
        {
          "energy_efficiency_rating": 2,
          "environmental_efficiency_rating": 2,
          "name": "roof",
          "description": "Pitched, 25 mm loft insulation",
        },
        {
          "energy_efficiency_rating": 4,
          "environmental_efficiency_rating": 4,
          "name": "roof",
          "description": "Pitched, 250 mm loft insulation",
        },
        {
          "energy_efficiency_rating": 0,
          "environmental_efficiency_rating": 0,
          "name": "floor",
          "description": "Suspended, no insulation (assumed)",
        },
        {
          "energy_efficiency_rating": 0,
          "environmental_efficiency_rating": 0,
          "name": "floor",
          "description": "Solid, insulated (assumed)",
        },
        {
          "energy_efficiency_rating": 3,
          "environmental_efficiency_rating": 3,
          "name": "window",
          "description": "Fully double glazed",
        },
        {
          "energy_efficiency_rating": 3,
          "environmental_efficiency_rating": 1,
          "name": "main_heating",
          "description": "Boiler and radiators, anthracite",
        },
        {
          "energy_efficiency_rating": 4,
          "environmental_efficiency_rating": 4,
          "name": "main_heating",
          "description": "Boiler and radiators, mains gas",
        },
        {
          "energy_efficiency_rating": 4,
          "environmental_efficiency_rating": 4,
          "name": "main_heating_controls",
          "description": "Programmer, room thermostat and TRVs",
        },
        {
          "energy_efficiency_rating": 5,
          "environmental_efficiency_rating": 5,
          "name": "main_heating_controls",
          "description": "Time and temperature zone control",
        },
        {
          "energy_efficiency_rating": 4,
          "environmental_efficiency_rating": 4,
          "name": "hot_water",
          "description": "From main system",
        },
        {
          "energy_efficiency_rating": 4,
          "environmental_efficiency_rating": 4,
          "name": "lighting",
          "description": "Low energy lighting in 50% of fixed outlets",
        },
        {
          "energy_efficiency_rating": 0,
          "environmental_efficiency_rating": 0,
          "name": "secondary_heating",
          "description": "Room heaters, electric",
        },
      ],
      "recommended_improvements": [
        {
          "energy_performance_rating_improvement": 50,
          "environmental_impact_rating_improvement": 50,
          "green_deal_category_code": "1",
          "improvement_category": "6",
          "improvement_code": "5",
          "improvement_description": nil,
          "improvement_title": "",
          "improvement_type": "Z3",
          "indicative_cost": "£100 - £350",
          "sequence": 1,
          "typical_saving": "360",
          "energy_performance_band_improvement": "e",
        },
        {
          "energy_performance_rating_improvement": 60,
          "environmental_impact_rating_improvement": 64,
          "green_deal_category_code": "3",
          "improvement_category": "2",
          "improvement_code": "1",
          "improvement_description": nil,
          "improvement_title": "",
          "improvement_type": "Z2",
          "indicative_cost": "2000",
          "sequence": 2,
          "typical_saving": "99",
          "energy_performance_band_improvement": "d",
        },
        {
          "energy_performance_rating_improvement": 60,
          "environmental_impact_rating_improvement": 64,
          "green_deal_category_code": "3",
          "improvement_category": "2",
          "improvement_code": nil,
          "improvement_description": "Improvement desc",
          "improvement_title": "",
          "improvement_type": "Z2",
          "indicative_cost": "1000",
          "sequence": 3,
          "typical_saving": "99",
          "energy_performance_band_improvement": "d",
        },
      ],
      "lzc_energy_sources": nil,
      "related_party_disclosure_number": nil,
      "related_party_disclosure_text": "No related party",
      "total_floor_area": 55.0,
      "status": "ENTERED",
      "environmental_impact_current": 52,
      "environmental_impact_potential": 74,
      "primary_energy_use": "230",
      "addendum": {
        "addendum_number": [
          1,
          8,
        ],
        "stone_walls": true,
        "system_build": true,
      },
      "gas_smart_meter_present": nil,
      "electricity_smart_meter_present": nil,
    }
  end

  let(:rdsap) do
    {
      assessment_id: "0000-0000-0000-0000-0000",
      assessment_status: "ENTERED",
      assessment_type: "RdSAP",
      assessment_expiry_date: Time.new(2030, 0o1, 30).utc.to_date,
      opt_out: false,
    }
  end
  let(:sap) do
    {
      assessment_id: "0000-0000-0000-0000-0002",
      assessment_status: "ENTERED",
      assessment_type: "SAP",
      assessment_expiry_date: Time.new(2030, 0o1, 30).utc.to_date,
      opt_out: false,
    }
  end
  let(:related_assessment_rdsap) { Domain::RelatedAssessment.new(**rdsap) }
  let(:related_assessment_sap) { Domain::RelatedAssessment.new(**sap) }
  let(:related_assessments) do
    [related_assessment_rdsap,
     related_assessment_sap]
  end
  let(:expected_assessments) do
    [related_assessment_sap]
  end
  let(:sap_assessment) do
    {
      "created_at" => Time.utc(2021, 2, 22),
      "opt_out" => false,
      "cancelled_at" => nil,
      "not_for_issue_at" => nil,
      "assessment_address_id" => "UPRN-000000000000",
      "country_name" => "England",
      "scheme_assessor_id" => "SPEC000000",
      "assessor_first_name" => "Someone",
      "assessor_last_name" => "Person",
      "assessor_telephone_number" => "010199991010101",
      "assessor_email" => "person@person.com",
      "scheme_id" => 1,
      "scheme_name" => "test scheme",
      "schema_type" => "SAP-Schema-19.0.0",
      "xml" => xml_sap_fixture,
      "green_deal_plan_id" => nil,
      "count_address_id_assessments" => 2,
    }
  end
  let(:xml_sap_fixture) do
    Samples.xml "SAP-Schema-19.0.0"
  end

  let(:expected_data) do
    {
      "type_of_assessment": "RdSAP",
      "assessment_id": "0000-0000-0000-0000-0000",
      "date_of_expiry": "2030-05-03",
      "date_of_assessment": "2020-05-04",
      "date_of_registration": "2020-05-04",
      "address": {
        "address_line1": "1 Some Street",
        "address_line2": "",
        "address_line3": "",
        "address_line4": nil,
        "town": "Whitbury",
        "postcode": "SW1A 2AA",
      },
      "assessor": {
        "scheme_assessor_id": "SPEC000000",
        "name": "Testa Sessor",
        "contact_details": {
          "email": "a@b.c",
          "telephone": "0555 497 2848",
        },
      },
      "current_carbon_emission": 2.4,
      "current_energy_efficiency_band": "e",
      "current_energy_efficiency_rating": 50,
      "dwelling_type": "Mid-terrace house",
      "estimated_energy_cost": "689.83",
      "heat_demand": {
        "current_space_heating_demand": 13_120,
        "current_water_heating_demand": 2285,
      },
      "heating_cost_current": "365.98",
      "heating_cost_potential": "250.34",
      "hot_water_cost_current": "200.40",
      "hot_water_cost_potential": "180.43",
      "lighting_cost_current": "123.45",
      "lighting_cost_potential": "84.23",
      "potential_carbon_emission": 1.4,
      "potential_energy_efficiency_band": "c",
      "potential_energy_efficiency_rating": 72,
      "potential_energy_saving": "174.83",
      "property_summary": [
        {
          "energy_efficiency_rating": 1,
          "environmental_efficiency_rating": 1,
          "name": "wall",
          "description": "Solid brick, as built, no insulation (assumed)",
        },
        {
          "energy_efficiency_rating": 4,
          "environmental_efficiency_rating": 4,
          "name": "wall",
          "description": "Cavity wall, as built, insulated (assumed)",
        },
        {
          "energy_efficiency_rating": 2,
          "environmental_efficiency_rating": 2,
          "name": "roof",
          "description": "Pitched, 25 mm loft insulation",
        },
        {
          "energy_efficiency_rating": 4,
          "environmental_efficiency_rating": 4,
          "name": "roof",
          "description": "Pitched, 250 mm loft insulation",
        },
        {
          "energy_efficiency_rating": 0,
          "environmental_efficiency_rating": 0,
          "name": "floor",
          "description": "Suspended, no insulation (assumed)",
        },
        {
          "energy_efficiency_rating": 0,
          "environmental_efficiency_rating": 0,
          "name": "floor",
          "description": "Solid, insulated (assumed)",
        },
        {
          "energy_efficiency_rating": 3,
          "environmental_efficiency_rating": 3,
          "name": "window",
          "description": "Fully double glazed",
        },
        {
          "energy_efficiency_rating": 3,
          "environmental_efficiency_rating": 1,
          "name": "main_heating",
          "description": "Boiler and radiators, anthracite",
        },
        {
          "energy_efficiency_rating": 4,
          "environmental_efficiency_rating": 4,
          "name": "main_heating",
          "description": "Boiler and radiators, mains gas",
        },
        {
          "energy_efficiency_rating": 4,
          "environmental_efficiency_rating": 4,
          "name": "main_heating_controls",
          "description": "Programmer, room thermostat and TRVs",
        },
        {
          "energy_efficiency_rating": 5,
          "environmental_efficiency_rating": 5,
          "name": "main_heating_controls",
          "description": "Time and temperature zone control",
        },
        {
          "energy_efficiency_rating": 4,
          "environmental_efficiency_rating": 4,
          "name": "hot_water",
          "description": "From main system",
        },
        {
          "energy_efficiency_rating": 4,
          "environmental_efficiency_rating": 4,
          "name": "lighting",
          "description": "Low energy lighting in 50% of fixed outlets",
        },
        {
          "energy_efficiency_rating": 0,
          "environmental_efficiency_rating": 0,
          "name": "secondary_heating",
          "description": "Room heaters, electric",
        },
      ],
      "recommended_improvements": [
        {
          "energy_performance_rating_improvement": 50,
          "environmental_impact_rating_improvement": 50,
          "green_deal_category_code": "1",
          "improvement_category": "6",
          "improvement_code": "5",
          "improvement_description": nil,
          "improvement_title": "",
          "improvement_type": "Z3",
          "indicative_cost": "£100 - £350",
          "sequence": 1,
          "typical_saving": "360",
          "energy_performance_band_improvement": "e",
        },
        {
          "energy_performance_rating_improvement": 60,
          "environmental_impact_rating_improvement": 64,
          "green_deal_category_code": "3",
          "improvement_category": "2",
          "improvement_code": "1",
          "improvement_description": nil,
          "improvement_title": "",
          "improvement_type": "Z2",
          "indicative_cost": "2000",
          "sequence": 2,
          "typical_saving": "99",
          "energy_performance_band_improvement": "d",
        },
        {
          "energy_performance_rating_improvement": 60,
          "environmental_impact_rating_improvement": 64,
          "green_deal_category_code": "3",
          "improvement_category": "2",
          "improvement_code": nil,
          "improvement_description": "Improvement desc",
          "improvement_title": "",
          "improvement_type": "Z2",
          "indicative_cost": "1000",
          "sequence": 3,
          "typical_saving": "99",
          "energy_performance_band_improvement": "d",
        },
      ],
      "lzc_energy_sources": nil,
      "related_party_disclosure_number": nil,
      "related_party_disclosure_text": "No related party",
      "total_floor_area": 55.0,
      "status": "ENTERED",
      "environmental_impact_current": 52,
      "environmental_impact_potential": 74,
      "primary_energy_use": "230",
      "addendum": {
        "addendum_number": [
          1,
          8,
        ],
        "stone_walls": true,
        "system_build": true,
      },
      "gas_smart_meter_present": nil,
      "electricity_smart_meter_present": nil,
      "address_id": "UPRN-000000000000",
      "opt_out": false,
      "superseded_by": nil,
      "related_assessments": expected_assessments,
      "country_name": "England",
    }
  end

  it "does not raise an error" do
    expect { described_class.new(assessment:, assessment_id:, related_assessments:) }.not_to raise_error
  end

  it "returns the expected certificate_summary_data" do
    result = described_class.new(assessment:, assessment_id:, related_assessments:)
    expect(result.certificate_summary_data).to eq expected_data
  end

  describe "#certificate_summary" do
    it "returns the expected certificate summary" do
      result = described_class.new(assessment:, assessment_id:, related_assessments:)
      expect(result.certificate_summary_data).to include expected_view_model_data
    end

    # add a test when an Argument is raised
  end

  describe "#update_address_id" do
    it "updates the certificate summary with an address_id" do
      result = described_class.new(assessment:, assessment_id:, related_assessments:)
      expect(result.certificate_summary_data[:address_id]).to eq "UPRN-000000000000"
    end
  end

  describe "#update_opt_out_status" do
    it "updates the certificate summary with opt_out_status" do
      result = described_class.new(assessment:, assessment_id:, related_assessments:)
      expect(result.certificate_summary_data[:opt_out]).to be false
    end
  end

  describe "#update_country_name" do
    it "updates the certificate summary with an country_name" do
      result = described_class.new(assessment:, assessment_id:, related_assessments:)
      expect(result.certificate_summary_data[:country_name]).to eq "England"
    end
  end

  describe "#update_related_assessments" do
    it "updates the certificate summary with related_assessments" do
      result = described_class.new(assessment:, assessment_id:, related_assessments:)
      expect(result.certificate_summary_data[:related_assessments]).to eq expected_assessments
      expect(result.certificate_summary_data[:superseded_by]).to be_nil
    end

    context "when there are no related assessments" do
      it "returns an empty array for related_assessments" do
        result = described_class.new(assessment:, assessment_id:, related_assessments: [])
        expect(result.certificate_summary_data[:related_assessments]).to eq []
      end

      it "returns nil for superseded_by" do
        result = described_class.new(assessment:, assessment_id:, related_assessments: [])
        expect(result.certificate_summary_data[:superseded_by]).to be_nil
      end
    end

    context "when there is a superseded assessment" do
      it "updates the certificate summary with superseded" do
        assessment_id = "0000-0000-0000-0000-0002"
        result = described_class.new(assessment:, assessment_id:, related_assessments:)
        expect(result.certificate_summary_data[:superseded_by]).to eq "0000-0000-0000-0000-0000"
      end
    end
  end
end
