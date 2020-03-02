describe UseCase::FindAssessmentsByAssessmentId do
  context 'when finding an assessment' do
    let(:find_assessments_without_stub_data) do
      described_class.new(DomesticEnergyAssessmentsGatewayStub.new([]))
    end

    let(:find_assessments_with_stub_data) do
      described_class.new(
        DomesticEnergyAssessmentsGatewayStub.new(
          [
            {
              assessmentId: '123-987',
              dateOfAssessment: '2020-01-13',
              dateRegistered: '2020-01-13',
              totalFloorArea: 1_000,
              typeOfAssessment: 'RdSAP',
              dwellingType: 'Top floor flat',
              addressSummary: '123 Victoria Street, London, SW1A 1BD',
              currentEnergyEfficiencyRating: 75,
              potentialEnergyEfficiencyRating: 80,
              postcode: 'SE1 7EZ',
              dateOfExpiry: '2021-01-02'
            },
            {
              assessmentId: '113-987',
              dateOfAssessment: '2020-01-14',
              dateRegistered: '2020-01-03',
              totalFloorArea: 1_000,
              typeOfAssessment: 'RdSAP',
              dwellingType: 'Top floor flat',
              addressSummary: '13 Victoria Street, London, SW1A 1BD',
              currentEnergyEfficiencyRating: 75,
              potentialEnergyEfficiencyRating: 80,
              postcode: 'SE1 7EZ',
              dateOfExpiry: '2021-01-02'
            }
          ]
        )
      )
    end

    it 'return empty when no assessments are present' do
      expect(
        find_assessments_without_stub_data.execute('1234-5678-9101-1121-3141')[:results]
      ).to eq([])
    end

    it 'return assessments where they exist' do
      response = find_assessments_with_stub_data.execute('1234-5678-9101-1121-3141')
      expect(response[:results].size).to eq(2)
    end
  end
end
