describe Domain::AssessmentBusDetails do
  let(:rrn) { "0123-4567-8901-2345-6789" }

  let(:arguments) do
    {
      bus_details:,
      assessment_summary:,
    }
  end

  let(:bus_details) do
    {
      "epc_rrn" => rrn,
      "report_type" => "RdSAP",
      "expiry_date" => Time.new(2030, 5, 3).to_date,
      "uprn" => "UPRN-000000000123",
    }
  end

  let(:assessment_summary) do
    {
      address: {
        address_line1: "22 Acacia Avenue",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "Anytown",
        postcode: "AB1 2CD",
      },
      current_energy_efficiency_band: "e",
      date_of_registration: "2020-05-04",
      date_of_expiry: Time.new(2030, 5, 3).to_date,
      superseded_by: nil,
      recommended_improvements: [
        { energy_performance_rating_improvement: 50,
          environmental_impact_rating_improvement: 50,
          green_deal_category_code: "1",
          improvement_category: "6",
          improvement_code: "5",
          improvement_description: nil,
          improvement_title: "",
          improvement_type: "A",
          indicative_cost: "£100 - £350",
          sequence: 1,
          typical_saving: "360",
          energy_performance_band_improvement: "e" },
        { energy_performance_rating_improvement: 60,
          environmental_impact_rating_improvement: 64,
          green_deal_category_code: "3",
          improvement_category: "2",
          improvement_code: "1",
          improvement_description: nil,
          improvement_title: "",
          improvement_type: "B",
          indicative_cost: "2000",
          sequence: 2,
          typical_saving: "99",
          energy_performance_band_improvement: "d" },
      ],
      type_of_assessment: "RdSAP",
      property_summary: [
        { energy_efficiency_rating: 1,
          environmental_efficiency_rating: 1,
          name: "wall",
          description: "Solid brick, as built, no insulation (assumed)" },
        { energy_efficiency_rating: 4,
          environmental_efficiency_rating: 4,
          name: "secondary_heating",
          description: "Electric bar heater" },
      ],
      dwelling_type: "Top-floor flat",
    }
  end

  let(:expected_data) do
    {
      epc_rrn: rrn,
      report_type: "RdSAP",
      expiry_date: "2030-05-03",
      cavity_wall_insulation_recommended: true,
      loft_insulation_recommended: true,
      secondary_heating: "Electric bar heater",
      address: {
        address_line1: "22 Acacia Avenue",
        address_line2: "",
        address_line3: "",
        address_line4: "",
        town: "Anytown",
        postcode: "AB1 2CD",
      },
      dwelling_type: "Top-floor flat",
      uprn: "000000000123",
      lodgement_date: "2020-05-04",
    }
  end

  let(:domain) { described_class.new(**arguments) }

  describe "#to_hash" do
    it "returns the expected data" do
      expect(domain.to_hash).to eq expected_data
    end

    context "when the urpn contains an RRN " do
      before do
        bus_details["uprn"] = "RRN-0000-0000-0000-0000-0001"
        expected_data[:uprn] = nil
      end

      it "has a nil for the uprn" do
        expect(domain.to_hash).to eq expected_data
      end
    end

    context "when there is no cavity wall insulation recommended" do
      before do
        assessment_summary[:recommended_improvements][1][:improvement_type] = "C"
        expected_data[:cavity_wall_insulation_recommended] = false
      end

      it "returns false for the cavity wall insulation" do
        expect(domain.to_hash).to eq expected_data
      end
    end

    context "when the assessment isn't a domestic assessment type" do
      before do
        assessment_summary[:type_of_assessment] = "CEPC"
        expected_data[:cavity_wall_insulation_recommended] = nil
        expected_data[:loft_insulation_recommended] = nil
      end

      it "does not return any insulation recommendations" do
        expect(domain.to_hash).to eq expected_data
      end
    end

    context "when there is no secondary heating" do
      context "with there being no property summary node" do
        before do
          assessment_summary[:property_summary] = nil
          expected_data[:secondary_heating] = nil
        end

        it "does not return any secondary heating information" do
          expect(domain.to_hash).to eq expected_data
        end
      end

      context "with there being no secondary heating feature" do
        before do
          assessment_summary[:property_summary][1][:name] = "wall"
          expected_data[:secondary_heating] = nil
        end

        it "does not return any secondary heating information" do
          expect(domain.to_hash).to eq expected_data
        end
      end

      context "with the feature description being empty" do
        before do
          assessment_summary[:property_summary][1][:description] = ""
          expected_data[:secondary_heating] = nil
        end

        it "does not return any secondary heating information" do
          expect(domain.to_hash).to eq expected_data
        end
      end
    end

    context "when there is no dwelling type" do
      context "with there being a property type instead" do
        before do
          assessment_summary.delete(:dwelling_type)
          assessment_summary[:property_type] = "Terraced house"
          expected_data[:dwelling_type] = "Terraced house"
        end

        it "returns the information for the property type" do
          expect(domain.to_hash).to eq expected_data
        end
      end

      context "with there being neither a property nor a dwelling type" do
        before do
          assessment_summary.delete(:dwelling_type)
          expected_data[:dwelling_type] = nil
        end

        it "returns no dwelling type information" do
          expect(domain.to_hash).to eq expected_data
        end
      end
    end
  end

  describe "#rrn" do
    it "returns the RRN" do
      expect(domain.rrn).to eq rrn
    end
  end
end
