describe Helper::DataExtractorHelper do
  let(:helper) { described_class.new }

  context "when extracting data" do
    let(:raw_data) do
      { foo: "bar",
        deep_hash: { another_hash: { treasure: "found me" } } }
    end

    let(:data_settings) do
      { text: { path: [:foo] },
        root_hash: { path: %i[deep_hash another_hash] },
        treasure: { root: :root_hash, path: [:treasure] } }
    end

    it "will return the extracted data" do
      result = helper.fetch_data(raw_data, data_settings)
      expect(result[:text]).to eq("bar")
    end

    it "will dig into multiple hashes" do
      result = helper.fetch_data(raw_data, data_settings)
      expect(result[:treasure]).to eq("found me")
    end
  end
end
