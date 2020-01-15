describe UseCase::FindAssessors do
  context 'when finding an assessor' do
    let(:find_assessors_without_stub_data) do
      postcodes_gateway =
        PostcodesGatewayStub.new(
          [{ 'postcode': 'BF1 3AD', 'latitude': 0, 'longitude': 0 }]
        )
      described_class.new(postcodes_gateway, AssessorGatewayFake.new([]), schemes_gateway)
    end

    let(:schemes_gateway) do
      SchemesGatewayStub.new([{ scheme_id: 25, name: 'Best scheme' }])
    end

    let(:find_assessors_without_existing_postcode) do
      postcodes_gateway = PostcodesGatewayStub.new([])
      described_class.new(postcodes_gateway, AssessorGatewayFake.new([]), schemes_gateway)
    end

    let(:find_assessors_without_scheme) do
      postcodes_gateway =
          PostcodesGatewayStub.new(
              [{ 'postcode': 'E12 0GL', 'latitude': 0, 'longitude': 0 }]
          )
      schemes_gateway =  SchemesGatewayStub.new([])
      results =   [
          {
              'firstName': 'Juan',
              'last_name': 'Uno',
              'contact_details': {
                  'telephone_number': 'string', 'email': 'user@example.com'
              },
              'search_results_comparison_postcode': 'SW1A 1AA',
              'distance': 0.1,
              'registered_by': 15
          },
          {
              'first_name': 'Juan',
              'last_name': 'Uno',
              'contact_details': {
                  'telephone_number': 'string', 'email': 'user@example.com'
              },
              'search_results_comparison_postcode': 'SW1A 1AA',
              'distance': 0.1,
              'registered_by': 15
          }
      ]
      described_class.new(postcodes_gateway, AssessorGatewayFake.new(results), schemes_gateway)
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
            {
              'firstName': 'Juan',
              'last_name': 'Uno',
              'contact_details': {
                'telephone_number': 'string', 'email': 'user@example.com'
              },
              'search_results_comparison_postcode': 'SW1A 1AA',
              'distance': 0.1,
              'registered_by': 25
            },
            {
              'first_name': 'Juan',
              'last_name': 'Uno',
              'contact_details': {
                'telephone_number': 'string', 'email': 'user@example.com'
              },
              'search_results_comparison_postcode': 'SW1A 1AA',
              'distance': 0.1,
              'registered_by': 25
            },
            {
              'first_name': 'Juan',
              'last_name': 'Uno',
              'contact_details': {
                'telephone_number': 'string', 'email': 'user@example.com'
              },
              'search_results_comparison_postcode': 'SW1A 1AA',
              'distance': 0.1,
              'registered_by': 25
            }
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

    it 'return an error when there is no scheme' do
      expect {
        find_assessors_without_scheme.execute('E12 0GL')
      }.to raise_exception UseCase::FindAssessors::SchemeNotFoundException
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
