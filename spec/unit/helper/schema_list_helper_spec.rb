describe Helper::SchemaListHelper do
  let(:valid_schema_name) { "RdSAP-Schema-20.0.0" }

  context "when checking a schema exists" do
    it "returns true if it exists under our schema list" do
      result = described_class.new(valid_schema_name).schema_exists?
      expect(result).to be(true)
    end

    it "returns false if no schema is in our list" do
      invalid_schema_name = "schema-name-not-in-our-list"
      result = described_class.new(invalid_schema_name).schema_exists?
      expect(result).to be(false)
    end
  end

  context "when getting the schema path" do
    it "returns the schema path if its in our schema list" do
      result = described_class.new(valid_schema_name).schema_path
      expect(result).to eq(
        "api/schemas/xml/RdSAP-Schema-20.0.0/RdSAP/Templates/RdSAP-Report.xsd",
      )
    end
  end
end
