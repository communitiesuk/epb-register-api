describe UseCase::ValidateAndLodgeAssessment do
  class ValidateLodgementUseCaseSpy
    def execute(*)
      @called = true
    end

    def is_called?
      @called
    end
  end

  class LodgeAssessmentUseCaseSpy
    def execute(*)
      @called = true
    end

    def is_called?
      @called
    end
  end

  class CheckAssessorBelongsToSchemeSpy
    def execute(*)
      @called = true
    end

    def is_called?
      @called
    end
  end

  let(:valid_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/RdSAP-19.01.xml"
  end

  let(:check_assessor_belongs_to_scheme_use_case) do
    CheckAssessorBelongsToSchemeSpy.new
  end
  let(:lodge_assessment_use_case) { LodgeAssessmentUseCaseSpy.new }
  let(:validate_lodgement_use_case) { ValidateLodgementUseCaseSpy.new }
  let(:assessments_xml_gateway) { AssessmentsXmlGatewaySpy.new }

  let(:use_case) do
    described_class.new(
      validate_lodgement_use_case,
      lodge_assessment_use_case,
    )
  end

  context "when validating an invalid schema name" do
    it "raises the error SchemaNotAccepted" do
      expect {
        use_case.execute(
          valid_xml,
          "Non-existent-RdSAP-Schema-19.0",
          "1",
          false,
        )
      }.to raise_exception(
        UseCase::ValidateAndLodgeAssessment::SchemaNotSupportedException,
      )
    end

    it "raises the error SchemaNotDefined" do
      expect {
        use_case.execute(valid_xml, nil, "1", false)
      }.to raise_exception(
        UseCase::ValidateAndLodgeAssessment::SchemaNotDefined,
      )
    end
  end
end
