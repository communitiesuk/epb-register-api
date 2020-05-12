describe Helper::DataExtractorHelper do
  let(:helper) { described_class.new }

  context "when extracting data" do
    let(:raw_data) do
      { foo: "bar",
        array: [
          { name: "Barry Garlow" },
          { name: "Barry Barlow" },
          { name: "Barry Darlow" },
        ],
        complex_hash: {
          "crazy": { name: "Barry Garlow" },
          "cool": [{ name: "Barry Barlow" },
                   { name: "Barry Darlow" }],
        },
        deep_hash: { another_hash: { treasure: "found me" } } }
    end

    let(:data_settings) do
      { text: { path: [:foo] },
        root_hash: { path: %i[deep_hash another_hash] },
        treasure: { root: :root_hash, path: [:treasure] },
        array_extraction: { path: [:array], extract: { full_name: { path: [:name] } } },
        smart_array_extraction: { path: [:complex_hash], bury_key: :key, extract: { full_name: { path: [:name] } } } }
    end

    let(:result) do
      helper.fetch_data(raw_data, data_settings)
    end

    it "will return the extracted data" do
      expect(result[:text]).to eq("bar")
    end

    it "will dig into multiple hashes" do
      expect(result[:treasure]).to eq("found me")
    end

    it "will extract arrays with keys inside" do
      expect(result[:array_extraction]).to eq([{ full_name: "Barry Garlow" }, { full_name: "Barry Barlow" }, { full_name: "Barry Darlow" }])
    end

    it "will extract an array and store the keys" do
      expect(result[:smart_array_extraction]).to eq([{ key: "crazy", full_name: "Barry Garlow" }, { key: "cool", full_name: "Barry Barlow" }, { key: "cool", full_name: "Barry Darlow" }])
    end
  end
end
