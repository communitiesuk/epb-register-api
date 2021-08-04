describe Gateway::AddressBaseHelper do
  context "when calling title_case_line with an address line from the address_base table" do
    it "is passed nil it should return nil" do
      expect(described_class.title_case_line(nil)).to be nil
    end

    it "is passed a line containing non-capitalised characters, the line is returned untransformed" do
      line = "ANY Street"
      expect(described_class.title_case_line(line)).to eq line
    end

    it "is passed a line in all caps containing words with no specialised casing rules" do
      line = "42 SIMPLE STREET"
      expected = "42 Simple Street"
      expect(described_class.title_case_line(line)).to eq expected
    end

    it "is passed a line with a street name containing an apostrophe" do
      line = "5 ST. JAMES'S GARDENS"
      expected = "5 St. James's Gardens"
      expect(described_class.title_case_line(line)).to eq expected
    end

    it "is passed a line with a street name starting O apostrophe" do
      line = "25 O'DONNELL LANE"
      expected = "25 O'Donnell Lane"
      expect(described_class.title_case_line(line)).to eq expected
    end

    it "is passed a line with a street name starting Mc" do
      line = "47 MCCARTHY COURT"
      expected = "47 McCarthy Court"
      expect(described_class.title_case_line(line)).to eq expected
    end

    it "is passed a line with a street name containing de la" do
      line = "3 CUL DE SAC"
      expected = "3 Cul De Sac"
      expect(described_class.title_case_line(line)).to eq expected
    end

    it "is passed a line with a street name starting de la" do
      line = "DE LA BERE CRESCENT"
      expected = "De La Bere Crescent"
      expect(described_class.title_case_line(line)).to eq expected
    end

    it "is passed a line with a street name containing an ordinal number" do
      line = "3RD FLOOR FLAT"
      expected = "3rd Floor Flat"
      expect(described_class.title_case_line(line)).to eq expected
    end

    it "is passed a line with a street name starting 3a" do
      line = "3A FLOOR FLAT"
      expected = "3a Floor Flat"
      expect(described_class.title_case_line(line)).to eq expected
    end
  end

  context "when calling title_case_address with a hash of keys" do
    it "is passed an address and converts address_lines but not town" do
      address = { address_line1: "199 COUNTRYSIDE ROAD", town: "SEASIDE TOWN" }
      expected = { address_line1: "199 Countryside Road", town: "SEASIDE TOWN" }
      expect(described_class.title_case_address(address)).to eq expected
    end
  end
end
