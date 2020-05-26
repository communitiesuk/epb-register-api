describe Helper::RegexHelper do
  describe "validating postcodes" do
    context "with a valid postcode" do
      describe "A0 0AA" do
        it "validates" do
          expect("A0 0AA").to match Regexp.new described_class::POSTCODE
        end
      end

      describe "A00AA" do
        it "validates" do
          expect("A00AA").to match Regexp.new described_class::POSTCODE
        end
      end
    end
  end
end
