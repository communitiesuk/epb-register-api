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

  let(:valid_xml) { Samples.xml "RdSAP-Schema-20.0.0" }

  let(:check_assessor_belongs_to_scheme_use_case) do
    CheckAssessorBelongsToSchemeSpy.new
  end

  let(:use_case) { described_class.new }

  context "when validating an invalid schema name" do
    it "raises the error SchemaNotAccepted" do
      expect {
        use_case.execute(
          valid_xml,
          "Non-existent-RdSAP-Schema-20.0.0",
          "1",
          false,
          false,
        )
      }.to raise_exception(
        UseCase::ValidateAndLodgeAssessment::SchemaNotSupportedException,
      )
    end

    it "raises the error SchemaNotDefined" do
      expect {
        use_case.execute(valid_xml, nil, "1", false, false)
      }.to raise_exception(
        UseCase::ValidateAndLodgeAssessment::SchemaNotDefined,
      )
    end
  end

  context "when validating a lodgement where the referenced UPRN does not exist" do
    it "raises the error NonexistentUprn" do
      remove_from_address_base(uprn: "0")
      expect {
        use_case.execute(
          valid_xml,
          "RdSAP-Schema-20.0.0",
          "1",
          false,
          false,
          )
      }.to raise_error UseCase::ValidateAndLodgeAssessment::NonexistentUprn
    end
  end
end
