describe UseCase::FetchDomesticEnergyAssessment do
  let(:domestic_epcs_gateway) { DomesticEpcsGatewayFake.new }

  let(:fetch_domestic_epc) { described_class.new(domestic_epcs_gateway) }

  context 'when there are no EPCs' do
    it 'raises a not found exception' do
      expect { fetch_domestic_epc.execute('123-456') }.to raise_exception(
        UseCase::FetchDomesticEnergyAssessment::NotFoundException
      )
    end
  end

  context 'when there is an EPC' do
    it 'returns the EPC' do
      domestic_epcs_gateway.domestic_epc =     {
            dateOfAssessment: '2020-01-13',
            dateRegistered: '2020-01-13',
            totalFloorArea: 1_000,
            typeOfAssessment: 'RdSAP',
            dwellingType: 'Top floor flat',
            addressSummary: '123 Victoria Street, London, SW1A 1BD',
            current_energy_efficiency_rating: 75,
            potential_energy_efficiency_rating: 80
          }
      result = fetch_domestic_epc.execute('123-456')

      expect(result).to eq(    {
            dateOfAssessment: '2020-01-13',
            dateRegistered: '2020-01-13',
            totalFloorArea: 1_000,
            typeOfAssessment: 'RdSAP',
            dwellingType: 'Top floor flat',
            addressSummary: '123 Victoria Street, London, SW1A 1BD',
            current_energy_efficiency_rating: 75,
            potential_energy_efficiency_rating: 80,
            currentEnergyEfficiencyRatingBand: 'c',
            potentialEnergyEfficiencyRatingBand: 'c'
          })
    end
  end
end
