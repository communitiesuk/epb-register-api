describe UseCase::FetchAssessment do
  subject(:use_case) do
    described_class.new(assessments_gateway: assessments_gateway,
                        assessors_gateway: assessors_gateway,
                        assessments_xml_gateway: assessments_xml_gateway)
  end

  let(:assessments_gateway) { instance_double Gateway::AssessmentsSearchGateway }
  let(:assessors_gateway) { instance_double Gateway::AssessorsGateway }
  let(:assessments_xml_gateway) { instance_double Gateway::AssessmentsXmlGateway }

  context "when an assessment id matches an RdSAP assessment" do
    assessment_id = "0000-1111-2222-3333-4444"
    xml = Samples.xml "RdSAP-Schema-20.0.0"
    assessment_scheme_assessor_id = "SPEC000000"

    before do
      allow(assessments_gateway).to receive(:search_by_assessment_id)
                                      .with(assessment_id, restrictive: false, is_scottish: false)
                                      .and_return([Domain::AssessmentSearchResult.new(assessment_id: assessment_id,
                                                                                      scheme_assessor_id: assessment_scheme_assessor_id,
                                                                                      date_of_assessment: Time.now,
                                                                                      date_of_expiry: Time.now + 10.years,
                                                                                      date_registered: Time.now)])

      allow(assessors_gateway).to receive(:fetch)
                                    .with(assessment_scheme_assessor_id)
                                    .and_return(Domain::Assessor.new(registered_by_id: "9"))

      allow(assessments_xml_gateway).to receive(:fetch).with(assessment_id, is_scottish: false).and_return({ xml: xml })
    end

    it "returns an assessments xml", :aggregate_failures do
      details = use_case.execute(assessment_id, "9")
      expect(details).to eq xml
    end
  end

  context "when an assessment id does not match an assessment" do
    assessment_id = "5555-5555-5555-5555-5555"

    before do
      allow(assessments_gateway).to receive(:search_by_assessment_id)
                                      .with(assessment_id, restrictive: false, is_scottish: false)
                                      .and_return([])
    end

    it "raises a not found exception" do
      expect { use_case.execute(assessment_id, "9") }.to raise_error(UseCase::FetchAssessment::NotFoundException)
    end
  end

  context "when an assessment is cancelled" do
    assessment_id = "0000-1111-2222-3333-4444"
    assessment_scheme_assessor_id = "SPEC000000"

    before do
      allow(assessments_gateway).to receive(:search_by_assessment_id)
                                      .with(assessment_id, restrictive: false, is_scottish: false)
                                      .and_return([Domain::AssessmentSearchResult.new(assessment_id: assessment_id,
                                                                                      scheme_assessor_id: assessment_scheme_assessor_id,
                                                                                      date_of_assessment: Time.now,
                                                                                      date_of_expiry: Time.now + 10.years,
                                                                                      date_registered: Time.now,
                                                                                      cancelled_at: Time.now)])
    end

    it "raises an assessment gone error", :aggregate_failures do
      expect { use_case.execute(assessment_id, "9") }.to raise_error(UseCase::FetchAssessment::AssessmentGone)
    end
  end

  context "when a cancelled scottish assessment is requested" do
    assessment_id = "0000-1111-2222-3333-4444"
    xml = Samples.xml "RdSAP-Schema-S-19.0"
    assessment_scheme_assessor_id = "SPEC000000"

    before do
      allow(assessments_gateway).to receive(:search_by_assessment_id)
                                      .with(assessment_id, restrictive: false, is_scottish: true)
                                      .and_return([Domain::AssessmentSearchResult.new(assessment_id: assessment_id,
                                                                                      scheme_assessor_id: assessment_scheme_assessor_id,
                                                                                      date_of_assessment: Time.now,
                                                                                      date_of_expiry: Time.now + 10.years,
                                                                                      date_registered: Time.now,
                                                                                      cancelled_at: Time.now)])

      allow(assessors_gateway).to receive(:fetch)
                                    .with(assessment_scheme_assessor_id)
                                    .and_return(Domain::Assessor.new(registered_by_id: "9"))

      allow(assessments_xml_gateway).to receive(:fetch).with(assessment_id, is_scottish: true).and_return({ xml: xml })
    end

    it "returns an assessments xml", :aggregate_failures do
      details = use_case.execute(assessment_id, "9", is_scottish: true)
      expect(details).to eq xml
    end
  end

  context "when the provided auth schemes do not match the scheme id from the assessment" do
    assessment_id = "0000-1111-2222-3333-4444"
    assessment_scheme_assessor_id = "SPEC000000"

    before do
      allow(assessments_gateway).to receive(:search_by_assessment_id)
                                      .with(assessment_id, restrictive: false, is_scottish: false)
                                      .and_return([Domain::AssessmentSearchResult.new(assessment_id: assessment_id,
                                                                                      scheme_assessor_id: assessment_scheme_assessor_id,
                                                                                      date_of_assessment: Time.now,
                                                                                      date_of_expiry: Time.now + 10.years,
                                                                                      date_registered: Time.now)])

      allow(assessors_gateway).to receive(:fetch)
                                    .with(assessment_scheme_assessor_id)
                                    .and_return(Domain::Assessor.new(registered_by_id: "9"))
    end

    it "raises an assessment gone error", :aggregate_failures do
      expect { use_case.execute(assessment_id, "1") }.to raise_error(UseCase::FetchAssessment::SchemeIdsDoNotMatch)
    end
  end
end
