describe Domain::CountryLookup do
  context "when a result references England only" do
    subject(:lookup) { described_class.new country_codes: %w[E] }

    it "is a match" do
      expect(lookup.match?).to be true
    end

    it "is not on a border" do
      expect(lookup.on_border?).to be false
    end

    it "reports as being in England" do
      expect(lookup.in_england?).to be true
    end

    it "reports as being not in Wales" do
      expect(lookup.in_wales?).to be false
    end

    it "returns a country id of 1" do
      expect(lookup.country_id).to eq 1
    end
  end

  context "when a result references Northern Ireland" do
    subject(:lookup) { described_class.new country_codes: %w[N] }

    it "is a match" do
      expect(lookup.match?).to be true
    end

    it "reports as being not in England" do
      expect(lookup.in_england?).to be false
    end

    it "reports as being not in Wales" do
      expect(lookup.in_wales?).to be false
    end

    it "reports as being in Northern Ireland" do
      expect(lookup.in_northern_ireland?).to be true
    end

    it "returns a country id of 3" do
      expect(lookup.country_id).to eq 3
    end
  end

  context "when a result references both England and Wales (as is in border area)" do
    subject(:lookup) { described_class.new country_codes: %w[W E] }

    it "is a match" do
      expect(lookup.match?).to be true
    end

    it "reports as being in England" do
      expect(lookup.in_england?).to be true
    end

    it "reports as being in Wales" do
      expect(lookup.in_wales?).to be true
    end

    it "reports as not being in Northern Ireland" do
      expect(lookup.in_northern_ireland?).to be false
    end

    it "reports out its country codes in sorted order, as symbols" do
      expect(lookup.country_codes).to eq %i[E W]
      expect(lookup.on_border?).to be true
    end

    it "returns a country id of 4" do
      expect(lookup.country_id).to eq 4
    end
  end

  context "when a result does not reference any country" do
    subject(:lookup) { described_class.new country_codes: [] }

    it "is not a match" do
      expect(lookup.match?).to be false
    end

    it "reports as being not in England" do
      expect(lookup.in_england?).to be false
    end

    it "reports as being not in Wales" do
      expect(lookup.in_wales?).to be false
    end

    it "returns a nil when there is no country_id" do
      expect(lookup.country_id).to be_nil
    end
  end

  describe "#uk_country_code" do
    subject(:lookup) { described_class.new country_codes: [:E] }

    it "returns 1 for England" do
      expect(lookup.uk_country_code("ENG")).to eq 1
    end

    it "returns 2 for Wales" do
      expect(lookup.uk_country_code("WLS")).to eq 2
    end

    it "returns 9 for NR (for backwards compatibility only)" do
      expect(lookup.uk_country_code("NR")).to eq 9
    end
  end
end
