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

  class FakeCheckAssessorBelongsToScheme
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
      check_assessor_belongs_to_scheme = FakeCheckAssessorBelongsToScheme.new

      use_case =
        described_class.new(
          validate_lodgement_use_case,
          lodge_assessment_use_case,
          check_assessor_belongs_to_scheme
        )
      use_case.execute(
        '0000-0000-0000-0000-0000',
        valid_xml,
        'application/xml+RdSAP-Schema-19.0',
        '1'
      )

      expect(validate_lodgement_use_case.is_called).to eq(true)
      expect(lodge_assessment_use_case.is_called).to eq(true)
    end
  end
end
