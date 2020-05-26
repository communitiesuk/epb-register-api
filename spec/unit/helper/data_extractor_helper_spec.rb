describe Helper::DataExtractorHelper do
  let(:helper) { described_class.new }

  context "when extracting data" do
    let(:raw_data) do
      {
        foo: "bar",
        array: [
          { name: "Barry Garlow" },
          { name: "Barry Barlow" },
          { name: "Barry Darlow" },
        ],
        complex_hash: {
          "crazy": { name: "Barry Garlow" },
          "cool": [{ name: "Barry Barlow" }, { name: "Barry Darlow" }],
        },
        complex_broken_hash: {
          "crazy": { name: "Barry Garlow" },
          "cool": [{ name: "Barry Barlow" }, { name: "Barry Darlow" }],
          "broken": "I don't comply",
        },
        deep_hash: { another_hash: { treasure: "found me" } },
        not_an_int: "99",
        not_snake_case: "HowGreatIsThis",
        mapped_entry: "1",
      }
    end

    let(:data_settings) do
      {
        text: { path: %i[foo] },
        root_hash: { path: %i[deep_hash another_hash] },
        treasure: { root: :root_hash, path: %i[treasure] },
        array_extraction: {
          path: %i[array], extract: { full_name: { path: %i[name] } }
        },
        smart_array_extraction: {
          path: %i[complex_hash],
          extract: { key: { path: %w[..] }, full_name: { path: %i[name] } },
        },
        supersmart_array_extraction: {
          required: %i[full_name],
          path: %i[complex_broken_hash],
          extract: { key: { path: %w[..] }, full_name: { path: %i[name] } },
        },
        default_value_extraction: {
          path: %i[something_that_doesnt_exist], default: []
        },
        make_an_int: { path: %i[not_an_int], cast: "integer" },
        make_snake_case: { path: %i[not_snake_case], cast: "snake_case" },
        make_map: { path: %i[mapped_entry], cast: "map", map: { "1": "great" } },
      }
    end

    let(:result) { helper.fetch_data(raw_data, data_settings) }

    it "will return the extracted data" do
      expect(result[:text]).to eq("bar")
    end

    it "will dig into multiple hashes" do
      expect(result[:treasure]).to eq("found me")
    end

    it "will extract arrays with keys inside" do
      expect(result[:array_extraction]).to eq(
        [
          { full_name: "Barry Garlow" },
          { full_name: "Barry Barlow" },
          { full_name: "Barry Darlow" },
        ],
      )
    end

    it "will extract an array and store the keys" do
      expect(result[:smart_array_extraction]).to eq(
        [
          { key: "crazy", full_name: "Barry Garlow" },
          { key: "cool", full_name: "Barry Barlow" },
          { key: "cool", full_name: "Barry Darlow" },
        ],
      )
    end

    it "will extract an array and store the keys, ignoring ones with missing keys" do
      expect(result[:supersmart_array_extraction]).to eq(
        [
          { key: "crazy", full_name: "Barry Garlow" },
          { key: "cool", full_name: "Barry Barlow" },
          { key: "cool", full_name: "Barry Darlow" },
        ],
      )
    end

    it "will extract a key and add a default value if it is missing" do
      expect(result[:default_value_extraction]).to eq([])
    end

    it "will extract a key and cast it to an integer" do
      expect(result[:make_an_int]).to eq(99)
    end

    it "will extract a key and cast it to snake case" do
      expect(result[:make_snake_case]).to eq("how_great_is_this")
    end

    it "will extract a key and cast it to map" do
      expect(result[:make_map]).to eq("great")
    end
  end
end
