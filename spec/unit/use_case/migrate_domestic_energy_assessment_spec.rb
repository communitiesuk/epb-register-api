describe UseCase::MigrateDomesticEnergyAssessment do
  context 'when migrating an EPC' do
    let(:epc_spy) { DomesticEnergyAssessmentsGatewaySpy.new }

    it 'passes the EPC data to the gateway' do
      use_case = described_class.new(epc_spy)

      result = use_case.execute('543-21', { some: 'assessment' })

      expect(result).to eq({ some: 'assessment', assessment_id: '543-21' })
      expect(epc_spy.assessment_id_saved).to eq('543-21')
      expect(epc_spy.assessment_saved).to eq(
        { some: 'assessment', assessment_id: '543-21' }
      )
    end
  end
end
