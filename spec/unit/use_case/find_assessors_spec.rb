describe UseCase::FindAssessors do
  context 'when finding an assessor' do
    let(:find_assessors_without_stub_data) do
      schemes_gateway =
        SchemesGatewayStub.new([{ scheme_id: 25, name: 'Best scheme' }])
      described_class.new(schemes_gateway, AssessorGatewayFake.new([]))
    end
    
    let(:find_assessors_with_stub_data) do
      schemes_gateway =
        SchemesGatewayStub.new([{ scheme_id: 25, name: 'Best scheme' }])
      described_class.new(schemes_gateway, AssessorGatewayFake.new(
                                                                [
                                                                  {
                                                                    'firstName': 'Juan',
                                                                    'lastName': 'Uno',
                                                                    'contactDetails': {
                                                                      'telephoneNumber': 'string',
                                                                      'email': 'user@example.com'
                                                                    },
                                                                    'searchResultsComparisonPostcode': 'SW1A 1AA',
                                                                    'registeredBy': {
                                                                      'schemeId': '432',
                                                                      'name': 'EPBs 4 U'
                                                                    },
                                                                    'distanceFromPostcodeInMiles': 0.1
                                                                  },
                                                                  {
                                                                    'firstName': 'Juan',
                                                                    'lastName': 'Uno',
                                                                    'contactDetails': {
                                                                      'telephoneNumber': 'string',
                                                                      'email': 'user@example.com'
                                                                    },
                                                                    'searchResultsComparisonPostcode': 'SW1A 1AA',
                                                                    'registeredBy': {
                                                                      'schemeId': '432',
                                                                      'name': 'EPBs 4 U'
                                                                    },
                                                                    'distanceFromPostcodeInMiles': 0.1
                                                                  },
                                                                  {
                                                                    'firstName': 'Juan',
                                                                    'lastName': 'Uno',
                                                                    'contactDetails': {
                                                                      'telephoneNumber': 'string',
                                                                      'email': 'user@example.com'
                                                                    },
                                                                    'searchResultsComparisonPostcode': 'SW1A 1AA',
                                                                    'registeredBy': {
                                                                      'schemeId': '432',
                                                                      'name': 'EPBs 4 U'
                                                                    },
                                                                    'distanceFromPostcodeInMiles': 0.1
                                                                  }
                                                                ]
      ))      
    end

    it 'return an error when the postcode is not valid' do
      expect{ find_assessors_without_stub_data.execute('733 34') }.to raise_exception UseCase::FindAssessors::PostcodeNotValid
    end

    it 'return empty when no assessors are present' do
      expect(find_assessors_without_stub_data.execute('E2 0SZ')[:results]).to eq([])
    end

    it 'contains timestamp of when query was made' do
      response = find_assessors_without_stub_data.execute('F3 1LL')

      expect(response[:timestamp]).to be_within(1).of(Time.now.to_i)
    end


    it 'return assessors where they exist' do
      response = find_assessors_with_stub_data.execute('S0 0CS')

      expect(response[:results].size).to eq(3)
    end
  end
end
