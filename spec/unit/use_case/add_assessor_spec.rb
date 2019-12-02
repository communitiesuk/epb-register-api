describe UseCase::AddAssessor do
  class SchemesGatewayStub
    def initialize(result)
      @result = result
    end
    def all(*)
      @result
    end
  end

  context 'when adding an assessor' do
    it 'returns an error if the scheme doesnt exist' do
      schemes_gateway = SchemesGatewayStub.new([])
      add_assessor = described_class.new(schemes_gateway)
      expect { add_assessor.execute(6) }.to raise_exception(UseCase::AddAssessor::SchemeNotFoundException)
    end

    it 'returns no errors if the scheme does exist' do
      schemes_gateway = SchemesGatewayStub.new([{scheme_id: 25, name: 'Best scheme'}])
      add_assessor = described_class.new(schemes_gateway)
      expect { add_assessor.execute("25") }.to_not raise_exception
    end
  end
end
