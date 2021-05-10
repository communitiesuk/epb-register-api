describe ViewModel::Export::DomesticExportView do
  context "When building a domestic SAP export" do
    subject do
      schema_type = "SAP-Schema-18.0.0".freeze
      xml = Nokogiri.XML Samples.xml(schema_type)
      wrapper = ViewModel::Factory.new.create(xml.to_s, schema_type.to_s)
      ViewModel::Export::DomesticExportView.new(wrapper)
    end

    let(:export) { read_json_fixture("domestic") }
    it "matches the expected JSON" do
      expect(subject.build).to eq(export)
    end
  end

  def read_json_fixture(file_name)
    path = File.join(Dir.pwd, "spec/fixtures/json_export/#{file_name}.json")
    file = File.read(path)
    JSON.parse(file, symbolize_names: true)
  end
end
