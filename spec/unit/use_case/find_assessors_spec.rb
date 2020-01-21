describe UseCase::FindAssessors do
  context 'when finding an assessor' do
    let(:find_assessors_without_stub_data) do
      postcodes_gateway =
        PostcodesGatewayStub.new(
          [{ 'postcode': 'BF1 3AD', 'latitude': 0, 'longitude': 0 }]
        )
      described_class.new(
        postcodes_gateway,
        AssessorGatewayFake.new([]),
        schemes_gateway
      )
    end

    let(:schemes_gateway) do
      SchemesGatewayStub.new([{ scheme_id: 25, name: 'Best scheme' }])
    end

    let(:find_assessors_without_existing_postcode) do
      postcodes_gateway = PostcodesGatewayStub.new([])
      described_class.new(
        postcodes_gateway,
        AssessorGatewayFake.new([]),
        schemes_gateway
      )
    end

    let(:find_assessors_with_stub_data) do
      postcodes_gateway =
        PostcodesGatewayStub.new(
          [{ 'postcode': 'BF1 3AD', 'latitude': 0, 'longitude': 0 }]
        )
      described_class.new(
        postcodes_gateway,
        AssessorGatewayFake.new(
          [
              { assessor: {
                               'first_name': 'Juan',
                               'last_name': 'Uno',
                               'middle_name': 'Middle',
                               'scheme_assessor_id': 'HEHSNHTBWEHJ',
                               'date_of_birth': '12/12/1963',
                               'contact_details': {
                                   'telephone_number': 'string', 'email': 'user@example.com'
                               },
                               'search_results_comparison_postcode': 'SW1A 1AA',
                               'registered_by': 25
                           }, 'distance': 0.1},
               { assessor: {
                                'first_name': 'Juan',
                                'last_name': 'Uno',
                                'middle_name': 'Middle',
                                'scheme_assessor_id': 'HEHSNHTBWEHJ',
                                'date_of_birth': '12/12/1963',
                                'contact_details': {
                                    'telephone_number': 'string', 'email': 'user@example.com'
                                },
                                'search_results_comparison_postcode': 'SW1A 1AA',
                                'registered_by': 25
                            }, 'distance': 0.1}
          ]
        ),
        schemes_gateway
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
      expect(response[:results].size).to eq(2)
    end
  end
end
