

describe "Rake open_data_export" do
  include RSpecRegisterApiServiceMixin
  context "when exporting data for open data" do
    before do
     scheme_id = add_scheme_and_get_id
      non_domestic_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
      non_domestic_assessment_id = non_domestic_xml.at("//CEPC:RRN")
      non_domestic_assessment_date = non_domestic_xml.at("//CEPC:Registration-Date")
      # Lodge a dec to ensure it is not exported
      domestic_xml =  Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec")
      domestic_assessment_id = domestic_xml.at("RRN")
      domestic_assessment_date =  domestic_xml.at("Registration-Date")

      add_assessor(
        scheme_id,
        "SPEC000000",
        AssessorStub.new.fetch_request_body(
          nonDomesticNos3: "ACTIVE",
          nonDomesticNos4: "ACTIVE",
          nonDomesticNos5: "ACTIVE",
          nonDomesticDec: "ACTIVE",
          domesticRdSap: "ACTIVE",
          domesticSap: "ACTIVE",
          nonDomesticSp3: "ACTIVE",
          nonDomesticCc4: "ACTIVE",
          gda: "ACTIVE",
          ),
        )

      non_domestic_assessment_date.children = "2020-05-04"
      lodge_assessment(
        assessment_body: non_domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        override: true,
        schema_name: "CEPC-8.0.0",
        )

      non_domestic_assessment_date.children = "2020-05-04"
      non_domestic_assessment_id.children = "0000-0000-0000-0000-0002"
      lodge_assessment(
        assessment_body: non_domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        override: true,
        schema_name: "CEPC-8.0.0",
        )

      non_domestic_assessment_date.children = "2018-05-04"
      non_domestic_assessment_id.children = "0000-0000-0000-0000-0001"
      lodge_assessment(
        assessment_body: non_domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        override: true,
        schema_name: "CEPC-8.0.0",
        )

      domestic_assessment_date.children = "2018-05-04"
      domestic_assessment_id.children = "0000-0000-0000-0000-0005"
      lodge_assessment(
        assessment_body: domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] },
        override: true,
        schema_name: "CEPC-8.0.0",
        )


    end

    # it 'should get data back from the use case' do
    #   expect(capture_rake_task_output).to eq(nil)
    # end

  end
end


def capture_rake_task_output
  stdout = StringIO.new
  $stdout = stdout
  Rake::Task["open_data_export"].invoke
  $stdout = STDOUT

  pp $stdout.class

  stdout.string
end
