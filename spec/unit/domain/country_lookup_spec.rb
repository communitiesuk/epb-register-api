describe Domain::CountryLookup do
  context "when a result references England only" do
    subject(:lookup) { described_class.new country_codes: %w[E] }

    it "is a match" do
      expect(lookup.match?).to be true
    end

    it "reports as being in england" do
      expect(lookup.in_england?).to be true
    end

    it "reports as being not in wales" do
      expect(lookup.in_wales?).to be false
    end
  end

  context "when a result references Northern Ireland" do
    subject(:lookup) { described_class.new country_codes: %w[N] }

    it "is a match" do
      expect(lookup.match?).to be true
    end

    it "reports as being not in england" do
      expect(lookup.in_england?).to be false
    end

    it "reports as being not in wales" do
      expect(lookup.in_wales?).to be false
    end

    it "reports as being in northern ireland" do
      expect(lookup.in_northern_ireland?).to be true
    end
  end

  context "when a result references both england and wales (as is in border area)" do
    subject(:lookup) { described_class.new country_codes: %w[W E] }

    it "is a match" do
      expect(lookup.match?).to be true
    end

    it "reports as being in england" do
      expect(lookup.in_england?).to be true
    end

    it "reports as being in wales" do
      expect(lookup.in_wales?).to be true
    end

    it "reports as not being in northern ireland" do
      expect(lookup.in_northern_ireland?).to be false
    end

    it "reports out its country codes in sorted order, as symbols" do
      expect(lookup.country_codes).to eq %i[E W]
    end
  end

  context "when a result does not reference any country" do
    subject(:lookup) { described_class.new country_codes: [] }

    it "is not a match" do
      expect(lookup.match?).to be false
    end

    it "reports as being not in england" do
      expect(lookup.in_england?).to be false
    end

    it "reports as being not in wales" do
      expect(lookup.in_wales?).to be false
    end
  end
end
