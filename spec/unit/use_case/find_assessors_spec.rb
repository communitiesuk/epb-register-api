describe UseCase::FindAssessors do
  context 'when finding an assessor' do
    let(:find_assessors_without_stub_data) do
      postcodes_gateway =
        PostcodesGatewayStub.new([{'postcode': 'BF1 3AD', 'latitude': 0, 'longitude': 0}])
      described_class.new(postcodes_gateway, AssessorGatewayFake.new([]))
    end

    let(:find_assessors_without_existing_postcode) do
      postcodes_gateway =
        PostcodesGatewayStub.new([])
      described_class.new(postcodes_gateway, AssessorGatewayFake.new([]))
    end

    let(:find_assessors_with_stub_data) do
      postcodes_gateway =
        PostcodesGatewayStub.new([{'postcode': 'BF1 3AD', 'latitude': 0, 'longitude': 0}])
      described_class.new(
        postcodes_gateway,
        AssessorGatewayFake.new(
          [
            {
              'firstName': 'Juan',
              'lastName': 'Uno',
              'contactDetails': {
                'telephoneNumber': 'string', 'email': 'user@example.com'
              },
              'searchResultsComparisonPostcode': 'SW1A 1AA',
              'registeredBy': { 'schemeId': '432', 'name': 'EPBs 4 U' },
              'distanceFromPostcodeInMiles': 0.1
            },
            {
              'firstName': 'Juan',
              'lastName': 'Uno',
              'contactDetails': {
                'telephoneNumber': 'string', 'email': 'user@example.com'
              },
              'searchResultsComparisonPostcode': 'SW1A 1AA',
              'registeredBy': { 'schemeId': '432', 'name': 'EPBs 4 U' },
              'distanceFromPostcodeInMiles': 0.1
            },
            {
              'firstName': 'Juan',
              'lastName': 'Uno',
              'contactDetails': {
                'telephoneNumber': 'string', 'email': 'user@example.com'
              },
              'searchResultsComparisonPostcode': 'SW1A 1AA',
              'registeredBy': { 'schemeId': '432', 'name': 'EPBs 4 U' },
              'distanceFromPostcodeInMiles': 0.1
            }
          ]
        )
      )
    end

    it 'return an error when the postcode is not valid' do
      expect {
        find_assessors_without_stub_data.execute('733 34')
      }.to raise_exception UseCase::FindAssessors::PostcodeNotValid
    end

    it 'return an error when the postcode is not registered' do
      expect {
        find_assessors_without_existing_postcode.execute('BF1 3AD')
      }.to raise_exception UseCase::FindAssessors::PostcodeNotRegistered
    end

    it 'return empty when no assessors are present' do
      expect(
        find_assessors_without_stub_data.execute('E2 0SZ')[:results]
      ).to eq([])
    end

    it 'return assessors where they exist' do
      response = find_assessors_with_stub_data.execute('S0 0CS')

      expect(response[:results].size).to eq(3)
    end
  end
end
