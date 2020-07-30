describe ViewModel::Cepc::CepcWrapper do
  context "when constructed with a valid CEPC 8.0.0 document" do
    let(:xml) { File.read File.join Dir.pwd, "spec/fixtures/samples/cepc.xml" }
    let(:cepc) { described_class.new xml, "CEPC-8.0.0" }

    it "returns the assessment ID" do
      expect(cepc.to_hash[:assessment_id]).to eq "0000-0000-0000-0000-0000"
    end

    it "returns the expiry date" do
      expect(cepc.to_hash[:date_of_expiry]).to eq "2026-05-04"
    end

    it "returns the address" do
      expect(cepc.to_hash[:address]).to eq(
        {
          address_line1: "2 Lonely Street",
          address_line2: nil,
          address_line3: nil,
          address_line4: nil,
          town: "Post-Town1",
          postcode: "A0 0AA",
        },
      )
    end

    it "returns the technical information" do
      expect(cepc.to_hash[:technical_information]).to eq(
        {
          main_heating_fuel: "Natural Gas",
          building_environment: "Air Conditioning",
          floor_area: "403",
          building_level: "3",
        },
      )
    end

    it "returns the building emission rate" do
      expect(cepc.to_hash[:building_emission_rate]).to eq "67.09"
    end

    it "returns the primary energy use" do
      expect(cepc.to_hash[:primary_energy_use]).to eq "413.22"
    end

    it "returns the related assessment ID" do
      expect(cepc.to_hash[:related_rrn]).to eq "4192-1535-8427-8844-6702"
    end

    it "returns the new build rating" do
      expect(cepc.to_hash[:new_build_rating]).to eq "28"
    end

    it "returns the existing build rating" do
      expect(cepc.to_hash[:existing_build_rating]).to eq "81"
    end

    it "returns the energy efficiency rating" do
      expect(cepc.to_hash[:energy_efficiency_rating]).to eq "80"
    end
  end
end
