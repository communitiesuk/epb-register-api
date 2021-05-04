require_relative "export_test_helper"

describe ViewModel::Export::CommercialExportView do
  context "When building a Commercial EPC export" do
    subject do
      schema_type = "CEPC-8.0.0"
      xml = Samples.xml(schema_type, "cepc")
      wrapper = ViewModel::Factory.new.create(xml, schema_type)
      ViewModel::Export::CommercialExportView.new(wrapper)
    end

    let(:export) { read_json_fixture("commercial") }
    it "matches the expected JSON" do
      expect(subject.build).to eq(export)
    end
  end
end
