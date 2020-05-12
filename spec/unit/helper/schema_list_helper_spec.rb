describe Helper::SchemaListHelper do
  let(:valid_schema_name) { "RdSAP-Schema-19.0" }

  context "when checking a schema exists" do
    it "will return true if it exisits under our schema list" do
      result = described_class.new(valid_schema_name).schema_exists?
      expect(result).to eq(true)
    end

    it "will return false if no schema is in our list" do
      invalid_schema_name = "schema-name-not-in-our-list"
      result = described_class.new(invalid_schema_name).schema_exists?
      expect(result).to eq(false)
    end
  end

  context "when getting the schema path" do
    it "will return the schema path if its in our schema list" do
      result = described_class.new(valid_schema_name).schema_path
      expect(result).to eq("api/schemas/xml/RdSAP-Schema-19.0/RdSAP/Templates/RdSAP-Report.xsd")
    end
  end

  context "when getting the report type" do
    it "will report type from the schema list" do
      result = described_class.new(valid_schema_name).report_type
      expect(result).to eq("RdSAP")
    end
  end
end
