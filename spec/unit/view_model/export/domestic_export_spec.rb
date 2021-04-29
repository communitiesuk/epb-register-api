describe ViewModel::ExportView do
  context "When building a domestic SAP export" do
    subject do
      schema_type = "SAP-Schema-18.0.0".freeze
      xml = Samples.xml(schema_type)
      wrapper = ViewModel::SapWrapper.new(xml, schema_type)
      ViewModel::ExportView.new(wrapper)
    end

    let(:export) { read_json_fixture("domestic") }
    it "matches the expected JSON" do
      expect(subject.build).to eq(export)
    end
  end
end

def read_json_fixture(file_name)
  path = File.join(Dir.pwd, "spec/fixtures/json_export/#{file_name}.json")
  file = File.read(path)
  JSON.parse(file, symbolize_names: true)
end
