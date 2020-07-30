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
        },
      )
    end
  end
end
