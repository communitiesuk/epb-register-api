describe "Gateway::ReportingGateway" do
  include RSpecRegisterApiServiceMixin
  context "test data extacted form the reporting gateway" do
    subject { Gateway::ReportingGateway.new }
    context "Insert two assessments and opt out one of them" do
      before(:all) do
        scheme_id = add_scheme_and_get_id
        add_super_assessor(scheme_id)
        schema = "RdSAP-Schema-20.0.0"
        xml = Nokogiri.XML Samples.xml(schema)
        call_lodge_assessment(scheme_id, schema, xml)
        xml.at("RRN").children = "0000-0000-0000-0000-0001"
        call_lodge_assessment(scheme_id, schema, xml)
        opt_out_assessment("0000-0000-0000-0000-0001")
      end

      let(:expected_data) do
        {
          "assessment_id" => "0000-0000-0000-0000-0001",
          "type_of_assessment" => "RdSAP",
          "address_line1" => "1 Some Street",
          "address_line2" => "",
          "address_line3" => "",
          "town" => "Whitbury",
          "postcode" => "A0 0AA",
          "date_registered" => "2020-05-04",
          "address_id" => "UPRN-000000000000",
        }
      end

      it "returns the opted out assessments only" do
        expect(subject.fetch_opted_out_assessments.count).to eq(1)
        expect(subject.fetch_opted_out_assessments[0]).to eq(expected_data)
      end
    end
  end
end
