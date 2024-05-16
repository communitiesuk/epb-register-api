describe UseCase::FetchAssessmentIdForCountryIdBackfill do
  subject(:use_case) { described_class.new(assessments_gateway:) }

  let(:assessments_gateway) { Gateway::AssessmentsGateway.new }

  context "when valid arguments are passed" do
    let(:date_from) { "2024-01-01" }
    let(:date_to) { "2024-01-31" }
    let(:assessment_ids) { %w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001 0000-0000-0000-0000-0002] }

    context "when expecting to get a list of assessment_ids" do
      before do
        allow(assessments_gateway).to receive(:fetch_assessment_id_by_date_and_type)
                                        .with(date_from:, date_to:)
                                        .and_return(assessment_ids)
      end

      it "does not raise an error" do
        expect { use_case.execute(date_from:, date_to:) }.not_to raise_error
      end

      it "returns assessment_ids found between two dates" do
        expect(use_case.execute(date_from:, date_to:)).to eq assessment_ids
      end
    end

    context "when an assessment type is passed" do
      let(:assessment_types) { %w[SAP] }

      before do
        allow(assessments_gateway).to receive(:fetch_assessment_id_by_date_and_type)
                                        .with(date_from:, date_to:, assessment_types:)
                                        .and_return(assessment_ids)
      end

      it "returns assessment_ids regardless of assessment type" do
        expect(use_case.execute(date_from:, date_to:, assessment_types:)).to eq assessment_ids
      end
    end
  end

  context "when invalid dates are passed" do
    let(:date_from) { "2024-01-01" }
    let(:date_to) { "2022-01-31" }

    it "raises an error" do
      expect { use_case.execute(date_from:, date_to:) }.to raise_error(Boundary::InvalidDates)
    end
  end

  context "when invalid assessment types are passed" do
    let(:date_from) { "2024-01-01" }
    let(:date_to) { "2024-01-31" }
    let(:assessment_types) { %w[SAP PEC] }

    before do
      allow(assessments_gateway).to receive(:fetch_assessment_id_by_date_and_type)
                                      .with(date_from:, date_to:, assessment_types:)
                                      .and_raise(StandardError)
    end

    it "raises an error" do
      expect { use_case.execute(date_from:, date_to:, assessment_types:) }.to raise_error(StandardError)
    end
  end

  context "when no assessment ids are returned" do
    let(:date_from) { "2024-01-01" }
    let(:date_to) { "2024-01-31" }
    let(:assessment_types) { %w[RdSAP SAP] }

    before do
      allow(assessments_gateway).to receive(:fetch_assessment_id_by_date_and_type).and_return([])
    end

    it "raises a no data error" do
      expect { use_case.execute(date_from:, date_to:, assessment_types:) }.to raise_error(Boundary::NoAssessments, "no assessments found for:  dates: 2024-01-01 - 2024-01-31 and assessment_types: [\"RdSAP\", \"SAP\"]")
    end
  end
end
