describe Gateway::RelatedAssessmentsGateway do
  include RSpecRegisterApiServiceMixin

  context "when getting related assessments" do
    subject(:gateway) { described_class.new }

    related_assessment_ids = %w[
      0000-0000-0000-0000-0001
      0000-0000-0000-0000-0003
      0000-0000-0000-0000-0042
    ]

    address_id = nil

    before(:all) do
      scheme_id = add_scheme_and_get_id
      add_super_assessor(scheme_id:)
      schema = "RdSAP-Schema-20.0.0"
      xml = Nokogiri.XML Samples.xml(schema)
      address_id = xml.at("UPRN").children.to_s
      related_assessment_ids.each do |assessment_id|
        xml.at("RRN").children = assessment_id
        call_lodge_assessment scheme_id:, schema_name: schema, xml_document: xml
      end
    end

    it "returns related assessment reference objects when calling by_address_id" do
      expect(gateway.by_address_id(address_id).map { |assessment| assessment.to_hash[:assessment_id] }.sort).to eq related_assessment_ids
    end

    it "returns related assessment IDs when calling related_assessment_ids" do
      expect(gateway.related_assessment_ids(address_id).sort).to eq related_assessment_ids
    end
  end
end
