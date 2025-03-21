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

  let(:expected_certificate_summary_without_assessor_details) do
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

  # set up for the related assessments
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

  # set up for green deal plan
  let(:arguments) do
    { green_deal_plan_id: "ABC654321DEF",
      start_date: Time.new(2020, 0o1, 30).utc.to_date,
      end_date: Time.new(2030, 0o2, 28).utc.to_date,
      provider_name: "The Bank",
      provider_telephone: "0800 0000000",
      provider_email: "lender@example.com",
      interest_rate: 12.3,
      fixed_interest_rate: true,
      charge_uplift_amount: 1.25,
      charge_uplift_date: Time.new(2025, 0o3, 29).utc.to_date,
      cca_regulated: true,
      structure_changed: false,
      measures_removed: false,
      charges: [{ end_date: "2030-03-29",
                  sequence: 0,
                  start_date: "2020-03-29",
                  daily_charge: 0.34 }],
      measures: [{ product: "WarmHome lagging stuff (TM)",
                   sequence: 0,
                   repaid_date: "2025-03-29",
                   measure_type: "Loft insulation" }],
      savings: [{ fuel_code: "39",
                  fuel_saving: 23_253,
                  standing_charge_fraction: 0 },
                { fuel_code: "40",
                  fuel_saving: -6331,
                  standing_charge_fraction: -0.9 },
                { fuel_code: "41",
                  fuel_saving: -15_561,
                  standing_charge_fraction: 0 }],
      estimated_savings: 1566 }
  end
  let(:green_deal_plan) do
    [Domain::GreenDealPlan.new(**arguments)]
  end

  let(:expected_certificate_summary) do
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
        "registered_by": { "name": "test scheme", "scheme_id": 1 },
        "first_name": "Someone",
        "last_name": "Person",
        "scheme_assessor_id": "SPEC000000",
        "contact_details":
          { "email": "a@b.c", "telephone_number": "0555 497 2848" },
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
      "green_deal_plan": green_deal_plan,
    }
  end

  it "does not raise an error" do
    expect { described_class.new(assessment:, assessment_id:, related_assessments:, green_deal_plan:) }.not_to raise_error
  end

  it "returns the expected certificate_summary_data" do
    result = described_class.new(assessment:, assessment_id:, related_assessments:, green_deal_plan:)
    expect(result.certificate_summary_data).to eq expected_certificate_summary
  end

  describe "#certificate_summary" do
    it "returns the expected certificate summary" do
      result = described_class.new(assessment:, assessment_id:, related_assessments:, green_deal_plan:)
      expect(result.certificate_summary_data).to include expected_certificate_summary_without_assessor_details
    end

    # add a test when an Argument is raised
  end

  describe "#update_address_id" do
    it "updates the certificate summary with an address_id" do
      result = described_class.new(assessment:, assessment_id:, related_assessments:, green_deal_plan:)
      expect(result.certificate_summary_data[:address_id]).to eq "UPRN-000000000000"
    end
  end

  describe "#update_opt_out_status" do
    it "updates the certificate summary with opt_out_status" do
      result = described_class.new(assessment:, assessment_id:, related_assessments:, green_deal_plan:)
      expect(result.certificate_summary_data[:opt_out]).to be false
    end
  end

  describe "#update_country_name" do
    it "updates the certificate summary with an country_name" do
      result = described_class.new(assessment:, assessment_id:, related_assessments:, green_deal_plan:)
      expect(result.certificate_summary_data[:country_name]).to eq "England"
    end
  end

  describe "#update_related_assessments" do
    it "updates the certificate summary with related_assessments" do
      result = described_class.new(assessment:, assessment_id:, related_assessments:, green_deal_plan:)
      expect(result.certificate_summary_data[:related_assessments]).to eq expected_assessments
      expect(result.certificate_summary_data[:superseded_by]).to be_nil
    end

    context "when there are no related assessments" do
      it "returns an empty array for related_assessments" do
        result = described_class.new(assessment:, assessment_id:, related_assessments: [], green_deal_plan:)
        expect(result.certificate_summary_data[:related_assessments]).to eq []
      end

      it "returns nil for superseded_by" do
        result = described_class.new(assessment:, assessment_id:, related_assessments: [], green_deal_plan:)
        expect(result.certificate_summary_data[:superseded_by]).to be_nil
      end
    end

    context "when there is a superseded assessment" do
      it "updates the certificate summary with superseded" do
        assessment_id = "0000-0000-0000-0000-0002"
        result = described_class.new(assessment:, assessment_id:, related_assessments:, green_deal_plan:)
        expect(result.certificate_summary_data[:superseded_by]).to eq "0000-0000-0000-0000-0000"
      end
    end
  end

  describe "#update_green_deals" do
    context "when the assessment type is RdSAP" do
      context "when there is data" do
        it "updates the certificate summary with green_deal_data" do
          result = described_class.new(assessment:, assessment_id:, related_assessments:, green_deal_plan:)
          expect(result.certificate_summary_data[:green_deal_plan]).to eq green_deal_plan
        end
      end

      context "when there is no data" do
        it "updates the certificate summary with green_deal_data with an empty array" do
          result = described_class.new(assessment:, assessment_id:, related_assessments:, green_deal_plan: nil)
          expect(result.certificate_summary_data[:green_deal_plan]).to eq []
        end
      end
    end

    context "when the assessment type is not RdSAP" do
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

      it "does not have a green_deal_plan attribute on certificate_summary_data" do
        result = described_class.new(assessment: sap_assessment, assessment_id: "0000-0000-0000-0000-0002", related_assessments:, green_deal_plan: nil)
        expect(result.certificate_summary_data.key?(:green_deal_plan)).to be false
      end
    end
  end

  describe "#update_assessor" do
    context "when there is email and telephone data in the xml" do
      it "returns the assessor information using the email and telephone data from the xml" do
        result = described_class.new(assessment:, assessment_id:, related_assessments:, green_deal_plan:)
        expect(result.certificate_summary_data[:assessor]).to eq(
          {
            "registered_by": { "name": "test scheme", "scheme_id": 1 },
            "first_name": "Someone",
            "last_name": "Person",
            "scheme_assessor_id": "SPEC000000",
            "contact_details":
              { "email": "a@b.c", "telephone_number": "0555 497 2848" },
          },
        )
      end
    end

    context "when there is no email or telephone data in the xml" do
      let(:assessment_xml_missing_contact_details) do
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
          "xml" => xml_missing_contact_details,
          "green_deal_plan_id" => nil,
          "count_address_id_assessments" => 2,
        }
      end

      let(:xml_missing_contact_details) do
        domestic_rdsap_xml = Samples.xml("RdSAP-Schema-20.0.0")
        domestic_rdsap_xml.gsub!("a@b.c", "")
        domestic_rdsap_xml.gsub!("0555 497 2848", "")
      end

      it "returns the email and telephone details from the assessors table" do
        result = described_class.new(assessment: assessment_xml_missing_contact_details, assessment_id:, related_assessments:, green_deal_plan:)
        expect(result.certificate_summary_data[:assessor]).to eq(
          {
            "registered_by": { "name": "test scheme", "scheme_id": 1 },
            "first_name": "Someone",
            "last_name": "Person",
            "scheme_assessor_id": "SPEC000000",
            "contact_details":
              { "email": "person@person.com", "telephone_number": "010199991010101" },
          },
        )
      end
    end
  end
end
