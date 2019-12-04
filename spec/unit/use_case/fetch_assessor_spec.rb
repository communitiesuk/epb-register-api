describe UseCase::FetchAssessor do
  VALID_ASSESSOR = {
      first_name: 'John',
      last_name: 'Smith',
      middle_names: 'Brain',
      date_of_birth: '1991-02-25'
  }.freeze

  class AssessorGatewayStub
    attr_reader :assessor

    def initialize(assessor = nil)
      @assessor = assessor
    end

    def fetch(*)
      @assessor
    end
  end

  let(:assessor_gateway) { AssessorGatewayStub.new }
  let(:schemes_gateway) { SchemesGatewayStub.new([{ scheme_id: 25, name: 'Best scheme' }]) }

  let(:fetch_assessor) { described_class.new(assessor_gateway, schemes_gateway) }

  context 'when there are no assessors' do
    it 'returns a nil' do
      expect{ fetch_assessor.execute('25','SCHE4321') }.to raise_exception(UseCase::FetchAssessor::AssessorNotFoundException)
    end
  end

  context 'when there are assessors' do
    it 'returns the first name of the assessor correctly' do
      assessor_gateway = AssessorGatewayStub.new(
          {
              registered_by: {scheme_id: 25, name: 'Best scheme'},
              scheme_assessor_id: 'SCHE001',
              first_name: VALID_ASSESSOR[:first_name],
              last_name: VALID_ASSESSOR[:last_name],
              date_of_birth: VALID_ASSESSOR[:date_of_birth]
          })
      fetch_assessor = described_class.new(assessor_gateway, schemes_gateway)
      expect(fetch_assessor.execute('25','SCHE001')[:first_name]).to eq('John')
    end

    it 'returns the last name of the assessor correctly' do
      assessor_gateway = AssessorGatewayStub.new(
          {
              registered_by: {scheme_id: 25, name: 'Best scheme'},
              scheme_assessor_id: 'SCHE001',
              first_name: VALID_ASSESSOR[:first_name],
              last_name: VALID_ASSESSOR[:last_name],
              date_of_birth: VALID_ASSESSOR[:date_of_birth]
          })
      fetch_assessor = described_class.new(assessor_gateway, schemes_gateway)
      expect(fetch_assessor.execute('25','SCHE001')[:last_name]).to eq('Smith')
    end

    it 'returns the middle names of the assessor correctly' do
      assessor_gateway = AssessorGatewayStub.new(
          {
              registered_by: {scheme_id: 25, name: 'Best scheme'},
              scheme_assessor_id: 'SCHE001',
              first_name: VALID_ASSESSOR[:first_name],
              middle_names: VALID_ASSESSOR[:middle_names],
              last_name: VALID_ASSESSOR[:last_name],
              date_of_birth: VALID_ASSESSOR[:date_of_birth]
          })
      fetch_assessor = described_class.new(assessor_gateway, schemes_gateway)
      expect(fetch_assessor.execute('25','SCHE001')[:middle_names]).to eq('Brain')
    end

    it 'returns the date of birth of the assessor correctly' do
      assessor_gateway = AssessorGatewayStub.new(
          {
              registered_by: {scheme_id: 25, name: 'Best scheme'},
              scheme_assessor_id: 'SCHE001',
              first_name: VALID_ASSESSOR[:first_name],
              last_name: VALID_ASSESSOR[:last_name],
              date_of_birth: VALID_ASSESSOR[:date_of_birth]
          })
      fetch_assessor = described_class.new(assessor_gateway, schemes_gateway)
      expect(fetch_assessor.execute('25','SCHE001')[:date_of_birth]).to eq('1991-02-25')
    end

    it 'returns the scheme id of the assessor correctly' do
      assessor_gateway = AssessorGatewayStub.new(
          {
              registered_by: {scheme_id: 25, name: 'Best scheme'},
              scheme_assessor_id: 'SCHE001',
              first_name: VALID_ASSESSOR[:first_name],
              last_name: VALID_ASSESSOR[:last_name],
              date_of_birth: VALID_ASSESSOR[:date_of_birth]
          })
      fetch_assessor = described_class.new(assessor_gateway, schemes_gateway)
      expect(fetch_assessor.execute('25','SCHE001')[:registered_by][:scheme_id]).to eq(25)
    end

    it 'returns the scheme name of the assessor correctly' do
      assessor_gateway = AssessorGatewayStub.new(
          {
              registered_by: {scheme_id: 25, name: 'Best scheme'},
              scheme_assessor_id: 'SCHE001',
              first_name: VALID_ASSESSOR[:first_name],
              last_name: VALID_ASSESSOR[:last_name],
              date_of_birth: VALID_ASSESSOR[:date_of_birth]
          })
      fetch_assessor = described_class.new(assessor_gateway, schemes_gateway)
      expect(fetch_assessor.execute('25','SCHE001')[:registered_by][:name]).to eq('Best scheme')
    end

    it 'returns an error if the scheme assessor ID does not exist' do
      assessor_gateway = AssessorGatewayStub.new(
          {
              registered_by: {scheme_id: 25, name: 'Best scheme'},
              scheme_assessor_id: 'SCHE001',
              first_name: VALID_ASSESSOR[:first_name],
              last_name: VALID_ASSESSOR[:last_name],
              date_of_birth: VALID_ASSESSOR[:date_of_birth]
          })
      fetch_assessor = described_class.new(assessor_gateway, schemes_gateway)
      expect{ fetch_assessor.execute('25','SCHE002') }.to raise_exception(UseCase::FetchAssessor::AssessorNotFoundException)
    end
  end
end
