describe "UseCase::ExportAssessmentAttributes" do
  include RSpecRegisterApiServiceMixin
  context "when exporting data for attribute storage call the use case" do
    let(:assessment_gateway) { instance_double(Gateway::AssessmentsGateway) }

    let(:assessment_xml_gateway) do
      instance_double(Gateway::AssessmentsXmlGateway)
    end

    let(:xml) { Nokogiri.XML Samples.xml("CEPC-8.0.0", "cepc") }

    subject do
      UseCase::ExportAssessmentAttributes.new(
        assessment_gateway,
        assessment_xml_gateway,
      )
    end

    it "calls the execute method to extract xml data from the gateway" do
      # using hash rockets to mimic the hashes created by activerecord whose keys are string and not symbols
      allow(assessment_gateway).to receive(:fetch_assessment_ids_by_range)
        .and_return(
          [
            {
              "assessment_id" => "0000-0000-0000-0000-0000",
              "type_of_assessment" => "CEPC",
            },
            {
              "assessment_id" => "0000-0000-0000-0000-0001",
              "type_of_assessment" => "CEPC",
            },
          ],
        )
      allow(assessment_xml_gateway).to receive(:fetch).and_return(
        { xml: xml, schema_type: "CEPC-8.0.0" },
      )
      expect(subject.execute(date_today)).to eq(
        [
          {
            assessment_id: "0000-0000-0000-0000-0000",
            type_of_assessment: "CEPC",
            xml: xml,
          },
          {
            assessment_id: "0000-0000-0000-0000-0001",
            type_of_assessment: "CEPC",
            xml: xml,
          },
        ],
      )
    end
  end
end
