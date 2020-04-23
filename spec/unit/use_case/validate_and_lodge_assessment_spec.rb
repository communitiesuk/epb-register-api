describe UseCase::ValidateAndLodgeAssessment do
  class FakeValidateLodgementUseCase
    def execute(*)
      @called = true
    end

    def is_called
      @called
    end
  end

  class FakeLodgeAssessmentUseCase
    def execute(*)
      @called = true
    end

    def is_called
      @called
    end
  end

  let(:valid_xml) do
    File.read File.join Dir.pwd, 'api/schemas/xml/examples/RdSAP-19.01.xml'
  end

  context 'when validating a valid RdSAP assessment' do
    it 'will call the two use cases' do
      validate_lodgement_use_case = FakeValidateLodgementUseCase.new
      lodge_assessment_use_case = FakeLodgeAssessmentUseCase.new

      use_case = described_class.new(validate_lodgement_use_case, lodge_assessment_use_case)
      use_case.execute("0000-0000-0000-0000-0000", valid_xml, "application/xml+RdSAP-Schema-19.0")

      expect(validate_lodgement_use_case.is_called).to eq(true)
      expect(lodge_assessment_use_case.is_called).to eq(true)
    end
  end
end
