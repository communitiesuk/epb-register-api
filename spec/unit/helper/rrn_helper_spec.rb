describe Helper::RrnHelper do
  describe "normalising RRN strings" do
    context "with a valid RRN" do
      describe "1234-5678-1234-5678-1234" do
        it "returns normalised RRN 1234-5678-1234-5678-1234" do
          expect(
            described_class.normalise_rrn_format("1234-5678-1234-5678-1234"),
          ).to eq("1234-5678-1234-5678-1234")
        end
      end

      describe "12345678123456781234" do
        it "returns normalised RRN 1234-5678-1234-5678-1234" do
          expect(
            described_class.normalise_rrn_format("12345678123456781234"),
          ).to eq("1234-5678-1234-5678-1234")
        end
      end

      describe "   1234-5678123-4567-81234     " do
        it "returns normalised RRN 1234-5678-1234-5678-1234" do
          expect(
            described_class.normalise_rrn_format(
              "   1234-5678123-4567-81234     ",
            ),
          ).to eq("1234-5678-1234-5678-1234")
        end
      end

      describe "   1-2-3-4-5-6-7-8-1-2-3-4-5-6-7-8-1-2-3-4    " do
        it "returns normalised RRN 1234-5678-1234-5678-1234" do
          expect(
            described_class.normalise_rrn_format(
              "   1-2-3-4-5-6-7-8-1-2-3-4-5-6-7-8-1-2-3-4    ",
            ),
          ).to eq("1234-5678-1234-5678-1234")
        end
      end
    end

    context "with an invalid RRN" do
      describe "too short: 123-5678-1234-5678-1234" do
        it "raises an RrnNotValid error" do
          expect {
            described_class.normalise_rrn_format "123-5678-1234-5678-1234"
          }.to raise_exception(Helper::RrnHelper::RrnNotValid)
        end
      end

      describe "too long: 1234-5678-1234-5678-12345" do
        it "raises an RrnNotValid error" do
          expect {
            described_class.normalise_rrn_format "1234-5678-1234-5678-12345"
          }.to raise_exception(Helper::RrnHelper::RrnNotValid)
        end
      end

      describe "with letters: 1234-AbCd-1234-5678-1234" do
        it "raises an RrnNotValid error" do
          expect {
            described_class.normalise_rrn_format "1234-AbCd-1234-5678-1234"
          }.to raise_exception(Helper::RrnHelper::RrnNotValid)
        end
      end

      describe "Some words: This is nothing like an RRN" do
        it "raises an RrnNotValid error" do
          expect {
            described_class.normalise_rrn_format "This is nothing like an RRN"
          }.to raise_exception(Helper::RrnHelper::RrnNotValid)
        end
      end

      describe "Empty" do
        it "raises an RrnNotValid error" do
          expect { described_class.normalise_rrn_format "" }.to raise_error(
            Helper::RrnHelper::RrnNotValid,
          )
        end
      end

      describe "All the dashes" do
        it "raises an RrnNotValid error" do
          expect {
            described_class.normalise_rrn_format "---------------------------------"
          }.to raise_error(Helper::RrnHelper::RrnNotValid)
        end
      end
    end
  end

  describe "hashing an RRN" do
    context "when given an rrn" do

      it 'returns a hashed string' do
        expect(
            described_class.hash_rrn("1234-5678-1234-2278-1234"),
            ).to eq("3219a657a59c669870b97a97a00fd722b81dbb02ffed384e794782f4991a5687")
      end
    end
  end
end
