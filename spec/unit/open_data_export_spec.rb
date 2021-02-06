describe "Rake open_data_export" do
  include RSpecRegisterApiServiceMixin
  context "when exporting data for open data" do
    after { HttpStub.off }

    let(:file_path) { "./spec/fixtures/open_data_export/" }

    before do
      scheme_id = add_scheme_and_get_id
      non_domestic_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc")
      non_domestic_assessment_id = non_domestic_xml.at("//CEPC:RRN")
      non_domestic_assessment_date =
        non_domestic_xml.at("//CEPC:Registration-Date")

      # Lodge a dec to ensure it is not exported
      dec_xml = Nokogiri.XML Samples.xml("CEPC-8.0.0", "dec")
      dec_assessment_id = dec_xml.at("RRN")
      dec_assessment_date = dec_xml.at("Registration-Date")

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
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
        schema_name: "CEPC-8.0.0",
      )

      non_domestic_assessment_date.children = "2020-05-04"
      non_domestic_assessment_id.children = "0000-0000-0000-0000-0002"
      lodge_assessment(
        assessment_body: non_domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
        schema_name: "CEPC-8.0.0",
      )

      non_domestic_assessment_date.children = "2018-05-04"
      non_domestic_assessment_id.children = "0000-0000-0000-0000-0001"
      lodge_assessment(
        assessment_body: non_domestic_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
        schema_name: "CEPC-8.0.0",
      )

      dec_assessment_date.children = "2020-10-10"
      dec_assessment_id.children = "0000-0000-0000-0000-0005"
      lodge_assessment(
        assessment_body: dec_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        override: true,
        schema_name: "CEPC-8.0.0",
      )
    end

    after do
      Dir.foreach(file_path) do |f|
        fn = File.join(file_path, f)
        File.delete(fn) if f != "." && f != ".."
      end
    end

    context "when we are unable to send data to S3" do
      xit "the rake can't send the file it should raise an error" do
        expect { get_task("open_data_export_cepc").invoke }.to output(
          /File could not be uploaded/,
        ).to_stdout
      end
    end

    xit "runs the task and create a csv for cepc and uploads " do
      get_task("open_data_export_cepc").invoke
      expect { get_task("open_data_export_cepc").invoke }.to output(true)
        .to_stdout
    end
  end
end
