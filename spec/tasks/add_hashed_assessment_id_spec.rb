describe "add hashed assessment_id rake", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:valid_rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }
  let(:valid_rdsap_ni_xml) { Samples.xml "RdSAP-Schema-NI-20.0.0" }
  let(:valid_cepc_xml) { Samples.xml "CEPC-8.0.0", "cepc" }
  let(:valid_dec_xml) { Samples.xml "CEPC-8.0.0", "dec" }

  let(:scheme_id) { add_scheme_and_get_id }

  let(:add_hashed_assessment_id_rake) { get_task("data_export:add_hashed_assessment_id") }

  context "when adding a hashed assessment_id for batch of certificates" do
    before do
      add_super_assessor(scheme_id:)

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        )
      rdsap_ni_xml = Nokogiri.XML valid_rdsap_ni_xml
      rdsap_ni_xml.at("RRN").children = "1234-5678-1234-2278-1234"
      lodge_assessment(
        assessment_body: rdsap_ni_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-NI-20.0.0",
        )
      cepc_xml = Nokogiri.XML valid_cepc_xml
      cepc_xml.at("//CEPC:RRN").children = "1234-5678-1234-2278-2345"
      lodge_assessment(
        assessment_body: cepc_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        )
      dec_xml = Nokogiri.XML valid_dec_xml
      dec_xml.at("RRN").children = "1234-5678-1234-2278-3456"
      lodge_assessment(
        assessment_body: dec_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        )
    end
    it 'updates the hashed_assessment_id columns' do
      add_hashed_assessment_id_rake.invoke

      hashed_assessment_id  =
        (ActiveRecord::Base
          .connection.execute "SELECT * FROM assessments WHERE assessment_id = '1234-5678-1234-2278-1234'").first
      
      expect(hashed_assessment_id["hashed_assessment_id"]).to eq('3219a657a59c669870b97a97a00fd722b81dbb02ffed384e794782f4991a5687')
    end
  end
end
