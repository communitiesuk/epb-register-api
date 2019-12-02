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
    VALID_ASSESSOR = JSON.parse({
        firstName: 'John',
        lastName: 'Smith',
        middleNames: 'Brain',
        dateOfBirth: '1991-02-25'
    }.to_json)

    it 'returns an error if the scheme doesnt exist' do
      schemes_gateway = SchemesGatewayStub.new([])
      add_assessor = described_class.new(schemes_gateway)
      expect { add_assessor.execute('6', 'SCHE24352', {}) }.to raise_exception(UseCase::AddAssessor::SchemeNotFoundException)
    end

    it 'returns no errors if the scheme does exist' do
      schemes_gateway = SchemesGatewayStub.new([{scheme_id: 25, name: 'Best scheme'}])
      add_assessor = described_class.new(schemes_gateway)
      expect { add_assessor.execute('25', 'SCHE904572', {}) }.to_not raise_exception
    end

    it 'returns the scheme that the assessor belongs to' do
      schemes_gateway = SchemesGatewayStub.new([{scheme_id: 25, name: 'Best scheme'}])
      add_assessor = described_class.new(schemes_gateway)

      expect(add_assessor.execute('25', 'SCHE234950', {})[:registeredBy]).to eq({schemeId: '25', name: 'Best scheme'})
    end

    it 'returns the scheme assessor ID' do
      schemes_gateway = SchemesGatewayStub.new([{scheme_id: 25, name: 'Best scheme'}])
      add_assessor = described_class.new(schemes_gateway)

      expect(add_assessor.execute('25', 'SCHE234950', {})[:schemeAssessorId]).to eq('SCHE234950')
    end

    it 'returns the assessors first name' do
      schemes_gateway = SchemesGatewayStub.new([{scheme_id: 25, name: 'Best scheme'}])
      add_assessor = described_class.new(schemes_gateway)

      expect(add_assessor.execute('25', 'SCHE234950', VALID_ASSESSOR)[:firstName]).to eq('John')
    end

    it 'returns the assessors last name' do
      schemes_gateway = SchemesGatewayStub.new([{scheme_id: 25, name: 'Best scheme'}])
      add_assessor = described_class.new(schemes_gateway)

      expect(add_assessor.execute('25', 'SCHE234950', VALID_ASSESSOR)[:lastName]).to eq('Smith')
    end

    it 'returns the assessors middle names' do
      schemes_gateway = SchemesGatewayStub.new([{scheme_id: 25, name: 'Best scheme'}])
      add_assessor = described_class.new(schemes_gateway)

      expect(add_assessor.execute('25', 'SCHE234950', VALID_ASSESSOR)[:middleNames]).to eq('Brain')
    end

    it 'returns the assessors date of birth' do
      schemes_gateway = SchemesGatewayStub.new([{scheme_id: 25, name: 'Best scheme'}])
      add_assessor = described_class.new(schemes_gateway)

      expect(add_assessor.execute('25', 'SCHE234950', VALID_ASSESSOR)[:dateOfBirth]).to eq('1991-02-25')
    end
  end
end
