describe UseCase::FetchAssessmentForScotlandPortal do
  subject(:use_case) do
    described_class.new(assessments_xml_gateway: assessments_xml_gateway)
  end

  let(:assessments_xml_gateway) { instance_double Gateway::AssessmentsXmlGateway }

  context "when an assessment id matches an RdSAP assessment" do
    assessment_id = "0000-1111-2222-3333-4444"
    xml = Samples.xml "RdSAP-Schema-20.0.0"

    before do
      allow(assessments_xml_gateway).to receive(:fetch).with(assessment_id, is_scottish: true).and_return({ xml: xml })
    end

    it "returns an assessments xml", :aggregate_failures do
      details = use_case.execute(assessment_id)
      expect(details).to eq xml
    end
  end

  context "when an assessment id does not match an assessment" do
    assessment_id = "5555-5555-5555-5555-5555"

    before do
      allow(assessments_xml_gateway).to receive(:fetch).with(assessment_id, is_scottish: true).and_return(nil)
    end

    it "raises a not found exception" do
      expect { use_case.execute(assessment_id) }.to raise_error(UseCase::FetchAssessmentForScotlandPortal::NotFoundException)
    end
  end
end
