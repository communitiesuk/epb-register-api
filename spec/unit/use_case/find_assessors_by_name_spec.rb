describe UseCase::FindAssessorsByName do
  context 'when finding an assessor' do
    let(:find_assessors_without_stub_data) do
      described_class.new(AssessorGatewayFake.new([]), schemes_gateway)
    end

    let(:schemes_gateway) do
      SchemesGatewayStub.new([{ scheme_id: 25, name: 'Best scheme' }])
    end

    let(:find_assessors_with_stub_data) do
      described_class.new(
        AssessorGatewayFake.new(
          [
            {
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
            },
            {
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
            }
          ]
        ),
        schemes_gateway
      )
    end

    it 'return empty when no assessors are present' do
      expect(
        find_assessors_without_stub_data.execute('Someones Name')[:data]
      ).to eq([])
    end

    it 'return assessors where they exist' do
      response = find_assessors_with_stub_data.execute('Someones Name')
      expect(response[:data].size).to eq(2)
    end
  end
end
