describe UseCase::FindAssessmentsByPostcode do
  context 'when finding an assessment' do
    let(:find_assessments_without_stub_data) do
      described_class.new(DomesticEnergyAssessmentsGatewayStub.new([]))
    end

    let(:find_assessments_with_stub_data) do
      described_class.new(
        DomesticEnergyAssessmentsGatewayStub.new(
          [
            {
              assessment_id: '123-987',
              date_of_assessment: '2020-01-13',
              date_registered: '2020-01-13',
              total_floor_area: 1_000,
              type_of_assessment: 'RdSAP',
              dwelling_type: 'Top floor flat',
              address_summary: '123 Victoria Street, London, SW1A 1BD',
              current_energy_efficiency_rating: 75,
              potential_energy_efficiency_rating: 80,
              postcode: 'SE1 7EZ',
              date_of_expiry: '2021-01-02',
              opt_out: false
            },
            {
              assessment_id: '123-987',
              date_of_assessment: '2020-01-13',
              date_registered: '2020-01-13',
              total_floor_area: 1_000,
              type_of_assessment: 'RdSAP',
              dwelling_type: 'Top floor flat',
              address_summary: '123 Victoria Street, London, SW1A 1BD',
              current_energy_efficiency_rating: 75,
              potential_energy_efficiency_rating: 80,
              postcode: 'SE1 7EZ',
              date_of_expiry: '2021-01-02',
              opt_out: false
            },
            {
              assessment_id: '647-987',
              date_of_assessment: '2020-04-14',
              date_registered: '2020-04-15',
              total_floor_area: 2_000,
              type_of_assessment: 'RdSAP',
              dwelling_type: 'bungalow',
              address_summary: '4 Henderson Drive, Luton, L12 1BD',
              current_energy_efficiency_rating: 65,
              potential_energy_efficiency_rating: 70,
              postcode: 'SE1 7EZ',
              date_of_expiry: '2021-04-14',
              opt_out: true
            }
          ]
        )
      )
    end

    it 'return empty when no assessments are present' do
      expect(
        find_assessments_without_stub_data.execute('E2 0SZ')[:data]
      ).to eq([])
    end

    it 'return assessments where they exist' do
      response = find_assessments_with_stub_data.execute('E2 0SZ')
      expect(response[:data].size).to eq(2)
    end
  end
end
