describe "UseCase::CertificateSummary", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    Timecop.freeze(2021, 2, 22, 0, 0, 0)
  end

  after(:all) do
    Timecop.return
  end

  context "when extracting a certificate summary data for a single certificate" do
    subject(:use_case) { UseCase::CertificateSummary::Fetch.new(certificate_summary_gateway:, green_deal_plans_gateway:, related_assessments_gateway:) }

    let(:certificate_summary_gateway) do
      instance_double(Gateway::CertificateSummaryGateway)
    end

    let(:green_deal_plans_gateway) do
      instance_double(Gateway::GreenDealPlansGateway)
    end

    let(:related_assessments_gateway) do
      instance_double(Gateway::RelatedAssessmentsGateway)
    end

    let(:gateway_data) do
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
        "count_address_id_assessments" => 1,
      }
    end

    let(:cepc_data) do
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
        "schema_type" => "CEPC-8.0.0",
        "xml" => xml_cepc_fixture,
        "green_deal_plan_id" => nil,
        "count_address_id_assessments" => 1,
      }
    end

    let(:gateway_data_with_green_deal) do
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
        "green_deal_plan_id" => "AC0000000005",
        "count_address_id_assessments" => 1,
      }
    end

    let(:xml_data_related_assessments) do
      {
        "created_at" => "2021-02-22 00:00:00 UTC",
        "opt_out" => false,
        "cancelled_at" => nil,
        "not_for_issue_at" => nil,
        "assessment_address_id" => "UPRN-000000000001",
        "country_id" => 3,
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

    let(:xml_cepc_fixture) do
      Samples.xml("CEPC-8.0.0", "cepc")
    end

    let(:green_deal_data) do
      [
        {
          "greenDealPlanId": "AC0000000005",
          "startDate": "2012-01-19",
          "endDate": "2032-01-13",
          "providerDetails": {
            "name": "HOME ENERGY AND LIFESTYLE MANAGEMENT",
            "telephone": "01010100000",
            "email": "admin@office.co.uk",
          },
          "interest": {
            "rate": "8.07",
            "fixed": true,
          },
          "chargeUplift": {
            "amount": "0.0",
            "date": nil,
          },
          "ccaRegulated": true,
          "structureChanged": false,
          "measuresRemoved": false,
          "measures": [
            {
              "product": "Solar photovoltaic panels",
              "repaidDate": "2032-01-15 00:00:00.000000",
            },
          ],
          "charges": [
            {
              "endDate": "2032-01-12 00:00:00.000000",
              "startDate": "2012-01-16 00:00:00.000000",
              "dailyCharge": 1.01,
            },
            {
              "endDate": "2032-01-13 00:00:00.000000",
              "startDate": "2032-01-13 00:00:00.000000",
              "dailyCharge": 0.8,
            },
          ],
          "savings": [
            {
              "fuelCode": "39",
              "fuelSaving": 2572,
              "standingChargeFraction": 0,
            },
          ],
          "estimatedSavings": 622,
        },
      ]
    end

    let(:related_assessments_data) do
    end

    let(:scheme_id) do
      add_scheme_and_get_id
    end

    let(:expected_data_without_assessor_details) do
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

    before do
      add_super_assessor(scheme_id:)
      allow(certificate_summary_gateway).to receive(:fetch).and_return(gateway_data)
    end

    it "does not raise and error" do
      expect { use_case.execute("0000-0000-0000-0000-0000") }.not_to raise_error
    end

    it "creates the certificate summary" do
      results = use_case.execute("0000-0000-0000-0000-0000")
      expect(results).to include(expected_data_without_assessor_details)
      expect(results[:address_id]).to eq "UPRN-000000000000"
      expect(results[:opt_out]).to be false
      expect(results[:country_name]).to eq "England"
      expect(results[:assessor]).to eq(
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

    context "when an non-dom certificate is passed to the use_case" do
      before do
        allow(certificate_summary_gateway).to receive(:fetch).with("0000-0000-0000-0000-0001").and_return(cepc_data)
      end

      it "raises an error for a non-dom certificate" do
        expect { use_case.execute("0000-0000-0000-0000-0001") }.to raise_error Boundary::InvalidAssessment
      end
    end

    context "when there is no green deal plan" do
      before do
        allow(green_deal_plans_gateway).to receive(:fetch)
      end

      it "does not call the green deal plan gateway when there is not a green deal plan" do
        use_case.execute("0000-0000-0000-0000-0000")
        expect(green_deal_plans_gateway).not_to have_received(:fetch)
      end
    end

    context "when there is a green deal plan" do
      before do
        allow(certificate_summary_gateway).to receive(:fetch).and_return(gateway_data_with_green_deal)
        allow(green_deal_plans_gateway).to receive(:fetch).and_return(green_deal_data)
      end

      it "does call the green deal plan gateway" do
        use_case.execute("0000-0000-0000-0000-0000")
        expect(green_deal_plans_gateway).to have_received(:fetch)
      end
    end

    context "when there are no related assessments" do
      before do
        allow(related_assessments_gateway).to receive(:by_address_id)
      end

      it "does not call the related assessments gateway" do
        use_case.execute("0000-0000-0000-0000-0000")
        expect(related_assessments_gateway).not_to have_received(:by_address_id)
      end
    end

    context "when there are related assessments" do
      before do
        allow(certificate_summary_gateway).to receive(:fetch).and_return(xml_data_related_assessments)
        allow(related_assessments_gateway).to receive(:by_address_id).and_return(related_assessments)
      end

      it "does call the related assessments gateway when there are related assessments" do
        use_case.execute("0000-0000-0000-0000-0000")
        expect(related_assessments_gateway).to have_received(:by_address_id)
      end
    end
  end
end
