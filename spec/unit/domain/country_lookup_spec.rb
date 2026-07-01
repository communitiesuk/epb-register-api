describe Domain::CountryLookup do
  test_country_codes = {
    E: "england",
    W: "wales",
    S: "scotland",
    N: "northern_ireland",
    L: "channel_islands",
    M: "isle_of_man",
    J: "in_unassigned_location",
  }

  context "when a result does not reference any country" do
    subject(:lookup) { described_class.new country_codes: [] }

    it "is not a match" do
      expect(lookup.match?).to be false
    end

    it "is not on a border" do
      expect(lookup.on_border?).to be false
    end

    test_country_codes.each_value do |m|
      it "reports as being not in #{m}" do
        expect(lookup.public_send(:"in_#{m}?")).to be false
      end
    end
  end

  test_country_codes.each do |code, name|
    context "when a result is in #{name}" do
      subject(:lookup) { described_class.new country_codes: [code] }

      it "is a match" do
        expect(lookup.match?).to be true
      end

      it "is not on a border" do
        expect(lookup.on_border?).to be false
      end

      it "reports as being in #{name}" do
        expect(lookup.public_send(:"in_#{name}?")).to be true
      end

      test_country_codes.each_value do |m|
        next if m == name

        it "reports as being not in #{m}" do
          expect(lookup.public_send(:"in_#{m}?")).to be false
        end
      end
    end
  end

  context "when a result references both England and Wales (as is in border area)" do
    subject(:lookup) { described_class.new country_codes: %w[W E] }

    it "is a match" do
      expect(lookup.match?).to be true
    end

    it "is on a border" do
      expect(lookup.on_border?).to be true
    end

    it "reports as being in england" do
      expect(lookup.in_england?).to be true
    end

    it "reports as being in wales" do
      expect(lookup.in_wales?).to be true
    end

    %w[northern_ireland scotland isle_of_man channel_islands in_unassigned_location].each do |m|
      it "reports as being not in #{m}" do
        expect(lookup.public_send(:"in_#{m}?")).to be false
      end
    end

    it "reports out its country codes in sorted order, as symbols" do
      expect(lookup.country_codes).to eq %i[E W]
    end
  end
end
