describe Domain::RelatedAssessments do
  let(:rdsap) do
    {
      assessment_id: "0000-0000-0000-0000-0001",
      assessment_status: "ENTERED",
      assessment_type: "RdSAP",
      assessment_expiry_date: Time.new(2030, 0o1, 30).utc.to_date,
      opt_out: false,
    }
  end
  let(:rdsap_opt_out) do
    {
      assessment_id: "0000-0000-0000-0000-0004",
      assessment_status: "ENTERED",
      assessment_type: "RdSAP",
      assessment_expiry_date: Time.new(2030, 0o1, 30).utc.to_date,
      opt_out: true,
    }
  end
  let(:sap) do
    {
      assessment_id: "0000-0000-0000-0000-0002",
      assessment_status: "ENTERED",
      assessment_type: "SAP",
      assessment_expiry_date: Time.new(2030, 0o1, 30).utc.to_date,
      opt_out: false,
    }
  end
  let(:cepc) do
    {
      assessment_id: "0000-0000-0000-0000-0003",
      assessment_status: "ENTERED",
      assessment_type: "CEPC",
      assessment_expiry_date: Time.new(2030, 0o1, 30).utc.to_date,
      opt_out: false,
    }
  end
  let(:related_assessment_rdsap) { Domain::RelatedAssessment.new(**rdsap) }
  let(:related_assessment_rdsap_opt_out) { Domain::RelatedAssessment.new(**rdsap_opt_out) }
  let(:related_assessment_sap) { Domain::RelatedAssessment.new(**sap) }
  let(:related_assessment_cepc) { Domain::RelatedAssessment.new(**cepc) }
  let(:related_assessments_array) do
    [related_assessment_rdsap,
     related_assessment_rdsap_opt_out,
     related_assessment_sap,
     related_assessment_cepc]
  end

  it "returns assessments expected assessments for the RdSAP assessment" do
    assessment_id = "0000-0000-0000-0000-0001"
    type_of_assessment = "RdSAP"

    expected_result = [
      related_assessment_sap,
    ]
    related_assessments = described_class.new(assessment_id:, type_of_assessment:, assessments: related_assessments_array)
    expect(related_assessments.assessments).to eq expected_result
    expect(related_assessments.superseded_by).to be_nil
  end

  it "returns assessments expected assessments for the SAP assessment" do
    assessment_id = "0000-0000-0000-0000-0002"
    type_of_assessment = "SAP"
    expected_result = [
      related_assessment_rdsap,
    ]
    related_assessments = described_class.new(assessment_id:, type_of_assessment:, assessments: related_assessments_array)
    expect(related_assessments.assessments).to eq expected_result
    expect(related_assessments.superseded_by).to eq "0000-0000-0000-0000-0001"
  end

  it "returns assessments expected assessments for the CEPC assessment" do
    assessment_id = "0000-0000-0000-0000-0003"
    type_of_assessment = "CEPC"
    expected_result = []
    related_assessments = described_class.new(assessment_id:, type_of_assessment:, assessments: related_assessments_array)
    expect(related_assessments.assessments).to eq expected_result
    expect(related_assessments.superseded_by).to be_nil
  end

  it "returns assessments expected assessments for an opted out assessment" do
    assessment_id = "0000-0000-0000-0000-0004"
    type_of_assessment = "RdSAP"
    expected_result = [
      related_assessment_rdsap,
      related_assessment_sap,
    ]
    related_assessments = described_class.new(assessment_id:, type_of_assessment:, assessments: related_assessments_array)
    expect(related_assessments.assessments).to eq expected_result
    expect(related_assessments.superseded_by).to eq "0000-0000-0000-0000-0001"
  end
end
