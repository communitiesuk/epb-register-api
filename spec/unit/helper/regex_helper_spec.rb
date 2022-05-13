describe Helper::RegexHelper do
  describe "validating postcodes" do
    let(:postcode_regex) { Regexp.new described_class::POSTCODE }

    context "with a valid postcode" do
      describe "A0 0AA" do
        it "validates" do
          expect(postcode_regex.match?("A0 0AA")).to be true
        end
      end

      describe "A00AA" do
        it "validates" do
          expect(postcode_regex.match?("A00AA")).to be true
        end
      end
    end

    context "with an invalid postcode" do
      describe "OVERTENCHARACTERS" do
        it "does not validate" do
          expect(postcode_regex.match?("OVERTENCHARACTERS")).to be false
        end
      end

      describe "A00" do
        it "does not validate" do
          expect(postcode_regex.match?("A00")).to be false
        end
      end

      describe "AAAA AAAAA" do
        it "does validate ten characters" do
          expect(postcode_regex.match?("AAAA AAAAA")).to be true
        end
      end
    end
  end

  describe "validating building reference numbers" do
    let(:address_id_regex) { Regexp.new described_class::ADDRESS_ID }

    context "with valid RRNs" do
      describe "RRN-0000-0000-0000-0000-0000" do
        it "validates" do
          expect(address_id_regex.match?("RRN-0000-0000-0000-0000-0000")).to be true
        end
      end
    end

    context "with invalid building reference numbers" do
      describe "0000-0000-0000-0000-0000" do
        it "does not validate" do
          expect(address_id_regex.match?("0000-0000-0000-0000-0000")).to be false
        end
      end

      describe "RRN-asdf-asdf-asdf-asdf-asdf" do
        it "does not validate" do
          expect(address_id_regex.match?("RRN-asdf-asdf-asdf-asdf-asdf")).to be false
        end
      end

      describe "RRN-1234-asdf-1234-asdf-1234" do
        it "does not validate" do
          expect(address_id_regex.match?("RRN-1234-asdf-1234-asdf-1234")).to be false
        end
      end

      describe "RRN-asdf-1234-asdf-1234-asdf" do
        it "does not validate" do
          expect(address_id_regex.match?("RRN-asdf-1234-asdf-1234-asdf")).to be false
        end
      end
    end
  end

  describe "validating UPRNs" do
    let(:uprn_regex) { Regexp.new described_class::UPRN }

    context "with valid UPRN" do
      it "validates" do
        expect(uprn_regex.match?("UPRN-012345678901")).to be true
      end
    end

    context "with RRN based address ID" do
      it "does not validate" do
        expect(uprn_regex.match?("RRN-0000-1111-2222-3333-4444")).to be false
      end
    end

    context "with a UPRN with too few digits" do
      it "does not validate" do
        expect(uprn_regex.match?("UPRN-01234567890")).to be false
      end
    end
  end

  describe "validating an RRN" do
    let(:rrn_regex) { Regexp.new described_class::RRN }

    context "with valid RRN" do
      it "validates" do
        expect(rrn_regex.match?("0000-1111-2222-3333-4444")).to be true
      end
    end

    context "with RRN with no dashes" do
      it "does not validate" do
        expect(rrn_regex.match?("00001111222233334444")).to be false
      end
    end

    context "with RRN with only four parts" do
      it "does not validate" do
        expect(rrn_regex.match?("0000-1111-2222-3333")).to be false
      end
    end

    context "with RRN with six parts" do
      it "does not validate" do
        expect(rrn_regex.match?("0000-1111-2222-3333-4444-5555")).to be false
      end
    end
  end

  describe "validating Green Deal Plan IDs" do
    let(:green_deal_plan_id_regex) { Regexp.new described_class::GREEN_DEAL_PLAN_ID }

    context "with valid Green Deal Plan IDs" do
      describe "AB0000000012" do
        it "validates" do
          expect(green_deal_plan_id_regex.match?("AB0000000012")).to be true
        end
      end
    end

    context "with invalid Green Deal Plan IDs" do
      describe "AB" do
        it "does not validate" do
          expect(green_deal_plan_id_regex.match?("AB")).to be false
        end
      end

      describe "AB0000000!12" do
        it "does not validate" do
          expect(green_deal_plan_id_regex.match?("AB0000000!12")).to be false
        end
      end

      describe "AB0000000 12" do
        it "does not validate" do
          expect(green_deal_plan_id_regex.match?("AB0000000 12")).to be false
        end
      end

      describe "AB_0000000012" do
        it "does not validate" do
          expect(green_deal_plan_id_regex.match?("AB_000000012")).to be false
        end
      end
    end
  end
end
