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

  class AssessmentsXmlGatewaySpy
    def send_to_db
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
      check_assessor_belongs_to_scheme_use_case,
      assessments_xml_gateway,
    )
  end

  context "when validating a valid RdSAP assessment" do
    it "will call the three use cases" do
      use_case.execute(
        "0000-0000-0000-0000-0000",
        valid_xml,
        "RdSAP-Schema-19.0",
        "1",
      )

      expect(validate_lodgement_use_case.is_called?).to be_truthy
      expect(lodge_assessment_use_case.is_called?).to be_truthy
      expect(check_assessor_belongs_to_scheme_use_case.is_called?).to be_truthy
    end
  end

  context "when validating an invalid schema name" do
    it "raises the error SchemaNotAccepted" do
      expect {
        use_case.execute(
          "0000-0000-0000-0000-0000",
          valid_xml,
          "Non-existent-RdSAP-Schema-19.0",
          "1",
        )
      }.to raise_exception(
        UseCase::ValidateAndLodgeAssessment::SchemaNotSupportedException,
      )
    end

    it "raises the error SchemaNotDefined" do
      expect {
        use_case.execute("0000-0000-0000-0000-0000", valid_xml, nil, "1")
      }.to raise_exception(
        UseCase::ValidateAndLodgeAssessment::SchemaNotDefined,
      )
    end
  end

  context "when failing to lodge an xml request" do
    it "will call send_to_db" do
      expect(assessments_xml_gateway.send_to_db).to be_truthy
    end
  end
end
