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

    context "with an invalid postcode" do
      describe "INVALID" do
        it "does not validate" do
          expect("INVALID").not_to match Regexp.new described_class::POSTCODE
        end
      end

      describe "A00" do
        it "does not validate" do
          expect("A00").not_to match Regexp.new described_class::POSTCODE
        end
      end

      describe "A00 0AAB" do
        it "does not validate" do
          expect("A00 0AAB").not_to match Regexp.new described_class::POSTCODE
        end
      end

      describe "A000AAB" do
        it "does not validate" do
          expect("A000AAB").not_to match Regexp.new described_class::POSTCODE
        end
      end

      describe "A000 0AA" do
        it "does not validate" do
          expect("A000 0AA").not_to match Regexp.new described_class::POSTCODE
        end
      end

      describe "A0000AA" do
        it "does not validate" do
          expect("A0000AA").not_to match Regexp.new described_class::POSTCODE
        end
      end

      describe "A0 0AAA" do
        it "does not validate" do
          expect("A0 0AAA").not_to match Regexp.new described_class::POSTCODE
        end
      end

      describe "A00AAA" do
        it "does not validate" do
          expect("A00AAA").not_to match Regexp.new described_class::POSTCODE
        end
      end
    end
  end

  describe "validating building reference numbers" do
    context "with valid RRNs" do
      describe "RRN-0000-0000-0000-0000-0000" do
        it "validates" do
          expect(
            "RRN-0000-0000-0000-0000-0000",
          ).to match Regexp.new described_class::ADDRESS_ID
        end
      end
    end

    context "with invalid building reference numbers" do
      describe "0000-0000-0000-0000-0000" do
        it "does not validate" do
          expect(
            "0000-0000-0000-0000-0000",
          ).not_to match Regexp.new described_class::ADDRESS_ID
        end
      end

      describe "RRN-asdf-asdf-asdf-asdf-asdf" do
        it "does not validate" do
          expect(
            "RRN-asdf-asdf-asdf-asdf-asdf",
          ).not_to match Regexp.new described_class::ADDRESS_ID
        end
      end

      describe "RRN-1234-asdf-1234-asdf-1234" do
        it "does not validate" do
          expect(
            "RRN-1234-asdf-1234-asdf-1234",
          ).not_to match Regexp.new described_class::ADDRESS_ID
        end
      end

      describe "RRN-asdf-1234-asdf-1234-asdf" do
        it "does not validate" do
          expect(
            "RRN-asdf-1234-asdf-1234-asdf",
          ).not_to match Regexp.new described_class::ADDRESS_ID
        end
      end
    end
  end

  describe "validating Green Deal Plan IDs" do
    context "with valid Green Deal Plan IDs" do
      describe "AB0000000012" do
        it "validates" do
          expect(
            "AB0000000012",
          ).to match Regexp.new described_class::GREEN_DEAL_PLAN_ID
        end
      end
    end

    context "with invalid Green Deal Plan IDs" do
      describe "AB" do
        it "does not validate" do
          expect(
            "AB",
          ).not_to match Regexp.new described_class::GREEN_DEAL_PLAN_ID
        end
      end

      describe "AB0000000!12" do
        it "does not validate" do
          expect(
            "AB0000000!12",
          ).not_to match Regexp.new described_class::GREEN_DEAL_PLAN_ID
        end
      end

      describe "AB0000000 12" do
        it "does not validate" do
          expect(
            "AB0000000 12",
          ).not_to match Regexp.new described_class::GREEN_DEAL_PLAN_ID
        end
      end

      describe "AB_0000000012" do
        it "does not validate" do
          expect(
            "AB_000000012",
          ).not_to match Regexp.new described_class::GREEN_DEAL_PLAN_ID
        end
      end
    end
  end
end
