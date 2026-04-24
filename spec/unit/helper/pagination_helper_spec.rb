describe Helper::PaginationHelper do
  context "when calculating the offset for pagination" do
    context "when requesting the first page" do
      it "calculates 0 offset" do
        expect(described_class.calculate_offset(1, 10)).to eq 0
      end
    end

    context "when requesting a higher page" do
      it "calculates how many multiples of the data per page to offset" do
        expect(described_class.calculate_offset(2, 10)).to eq 10
      end
    end

    context "when a negative page is requested" do
      it "calculates 0 offset" do
        expect(described_class.calculate_offset(-2, 10)).to eq 0
      end
    end
  end
end
