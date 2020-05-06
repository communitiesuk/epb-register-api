describe UseCase::ValidateAndLodgeAssessment do
  class ValidateLodgementUseCaseSpy
    def execute(*)
      @called = true
    end

    def is_called
      @called
    end
  end

  class LodgeAssessmentUseCaseSpy
    def execute(*)
      @called = true
    end

    def is_called
      @called
    end
  end

  class CheckAssessorBelongsToSchemeSpy
    def execute(*)
      @called = true
    end

    def is_called
      @called
    end
  end

  let(:valid_xml) do
    File.read File.join Dir.pwd, "api/schemas/xml/examples/RdSAP-19.01.xml"
  end

  context "when validating a valid RdSAP assessment" do
    it "will call the two use cases" do
      validate_lodgement_use_case = ValidateLodgementUseCaseSpy.new
      lodge_assessment_use_case = LodgeAssessmentUseCaseSpy.new
      check_assessor_belongs_to_scheme = CheckAssessorBelongsToSchemeSpy.new

      use_case =
        described_class.new(
          validate_lodgement_use_case,
          lodge_assessment_use_case,
          check_assessor_belongs_to_scheme,
        )
      use_case.execute(
        "0000-0000-0000-0000-0000",
        valid_xml,
        "RdSAP-Schema-19.0",
        "1",
      )

      expect(validate_lodgement_use_case.is_called).to eq(true)
      expect(lodge_assessment_use_case.is_called).to eq(true)
    end
  end

  context "when validating an invalid schema name" do
    it "raises the error SchemaNotAccepted" do
      validate_lodgement_use_case = ValidateLodgementUseCaseSpy.new
      lodge_assessment_use_case = LodgeAssessmentUseCaseSpy.new
      check_assessor_belongs_to_scheme = CheckAssessorBelongsToSchemeSpy.new

      use_case =
        described_class.new(
          validate_lodgement_use_case,
          lodge_assessment_use_case,
          check_assessor_belongs_to_scheme,
        )

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
      validate_lodgement_use_case = ValidateLodgementUseCaseSpy.new
      lodge_assessment_use_case = LodgeAssessmentUseCaseSpy.new
      check_assessor_belongs_to_scheme = CheckAssessorBelongsToSchemeSpy.new

      use_case =
        described_class.new(
          validate_lodgement_use_case,
          lodge_assessment_use_case,
          check_assessor_belongs_to_scheme,
          )

      expect {
        use_case.execute(
          "0000-0000-0000-0000-0000",
          valid_xml,
          nil,
          "1",
          )
      }.to raise_exception(
             UseCase::ValidateAndLodgeAssessment::SchemaNotDefined,
             )
    end
  end
end
