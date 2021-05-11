describe "UseCase::ExportAssessmentAttributes" do
  include RSpecRegisterApiServiceMixin
  context "when exporting data for attribute storage call the use case" do
    let(:assessment_gateway) { instance_double(Gateway::AssessmentsGateway) }

    let(:assessment_xml_gateway) do
      instance_double(Gateway::AssessmentsXmlGateway)
    end

    subject do
      UseCase::ExportAssessmentAttributes.new(
        assessment_gateway,
        assessment_xml_gateway,
      )
    end

    it "call the execute method to extract xml data from the gateway" do
      allow(assessment_gateway).to receive(:fetch_assessment_ids_by_range)
        .and_return([1, 2, 3])
      allow(assessment_xml_gateway).to receive(:fetch).with("001")
      expect(subject.execute(date_today)).to eq([{}, {}, {}])
    end
  end
end
