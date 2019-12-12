describe UseCase::FetchAssessor do

  let (:valid_assessor) do
    {
      first_name: 'John',
      last_name: 'Smith',
      middle_names: 'Brain',
      date_of_birth: '1991-02-25'
    }
  end

  class AssessorGatewayStub
    attr_reader :assessor

    def initialize(assessor = nil)
      @assessor = assessor
    end

    def fetch(*)
      @assessor
    end
  end

  class SchemesGatewayStub
    def initialize(result)
      @result = result
    end

    def all(*)
      @result
    end
  end

  let(:assessor_gateway) { AssessorGatewayStub.new }
  let(:schemes_gateway) do
    SchemesGatewayStub.new([{ scheme_id: 25, name: 'Best scheme' }])
  end

  let(:fetch_assessor) do
    described_class.new(assessor_gateway, schemes_gateway)
  end

  context 'when there are no assessors' do
    it 'returns a nil' do
      expect { fetch_assessor.execute('25', 'SCHE4321') }.to raise_exception(
        UseCase::FetchAssessor::AssessorNotFoundException
      )
    end
  end

  context 'when there are assessors' do
    it 'returns the first name of the assessor correctly' do
      assessor_gateway =
        AssessorGatewayStub.new(
          {
            registered_by: 25,
            scheme_assessor_id: 'SCHE001',
            first_name: valid_assessor[:first_name],
            last_name: valid_assessor[:last_name],
            date_of_birth: valid_assessor[:date_of_birth]
          }
        )
      fetch_assessor = described_class.new(assessor_gateway, schemes_gateway)
      expect(fetch_assessor.execute('25', 'SCHE001')[:first_name]).to eq('John')
    end

    it 'returns the last name of the assessor correctly' do
      assessor_gateway =
        AssessorGatewayStub.new(
          {
            registered_by: 25,
            scheme_assessor_id: 'SCHE001',
            first_name: valid_assessor[:first_name],
            last_name: valid_assessor[:last_name],
            date_of_birth: valid_assessor[:date_of_birth]
          }
        )
      fetch_assessor = described_class.new(assessor_gateway, schemes_gateway)
      expect(fetch_assessor.execute('25', 'SCHE001')[:last_name]).to eq('Smith')
    end

    it 'returns the middle names of the assessor correctly' do
      assessor_gateway =
        AssessorGatewayStub.new(
          {
            registered_by: 25,
            scheme_assessor_id: 'SCHE001',
            first_name: valid_assessor[:first_name],
            middle_names: valid_assessor[:middle_names],
            last_name: valid_assessor[:last_name],
            date_of_birth: valid_assessor[:date_of_birth]
          }
        )
      fetch_assessor = described_class.new(assessor_gateway, schemes_gateway)
      expect(fetch_assessor.execute('25', 'SCHE001')[:middle_names]).to eq(
        'Brain'
      )
    end

    it 'returns the date of birth of the assessor correctly' do
      assessor_gateway =
        AssessorGatewayStub.new(
          {
            registered_by: 25,
            scheme_assessor_id: 'SCHE001',
            first_name: valid_assessor[:first_name],
            last_name: valid_assessor[:last_name],
            date_of_birth: valid_assessor[:date_of_birth]
          }
        )
      fetch_assessor = described_class.new(assessor_gateway, schemes_gateway)
      expect(fetch_assessor.execute('25', 'SCHE001')[:date_of_birth]).to eq(
        '1991-02-25'
      )
    end

    it 'returns the scheme id of the assessor correctly' do
      assessor_gateway =
        AssessorGatewayStub.new(
          {
            registered_by: 25,
            scheme_assessor_id: 'SCHE001',
            first_name: valid_assessor[:first_name],
            last_name: valid_assessor[:last_name],
            date_of_birth: valid_assessor[:date_of_birth]
          }
        )
      fetch_assessor = described_class.new(assessor_gateway, schemes_gateway)
      expect(
        fetch_assessor.execute('25', 'SCHE001')[:registered_by][:scheme_id]
      ).to eq(25)
    end

    it 'returns the scheme name of the assessor correctly' do
      assessor_gateway =
        AssessorGatewayStub.new(
          {
            registered_by: 25,
            scheme_assessor_id: 'SCHE001',
            first_name: valid_assessor[:first_name],
            last_name: valid_assessor[:last_name],
            date_of_birth: valid_assessor[:date_of_birth]
          }
        )
      fetch_assessor = described_class.new(assessor_gateway, schemes_gateway)
      expect(
        fetch_assessor.execute('25', 'SCHE001')[:registered_by][:name]
      ).to eq('Best scheme')
    end

    it 'returns an error if the scheme assessor ID does not exist' do
      assessor_gateway =
        AssessorGatewayStub.new(
          {
            registered_by: { scheme_id: 25, name: 'Best scheme' },
            scheme_assessor_id: 'SCHE001',
            first_name: valid_assessor[:first_name],
            last_name: valid_assessor[:last_name],
            date_of_birth: valid_assessor[:date_of_birth]
          }
        )
      fetch_assessor = described_class.new(assessor_gateway, schemes_gateway)
      expect { fetch_assessor.execute('25', 'SCHE002') }.to raise_exception(
        UseCase::FetchAssessor::AssessorNotFoundException
      )
    end
  end
end
