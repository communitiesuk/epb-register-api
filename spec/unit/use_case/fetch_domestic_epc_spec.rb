describe UseCase::FetchDomesticEpc do
  let(:domestic_epcs_gateway) { DomesticEpcsGatewayFake.new }

  let(:fetch_domestic_epc) { described_class.new(domestic_epcs_gateway) }

  context 'when there are no EPCs' do
    it 'raises a not found exception' do
      expect { fetch_domestic_epc.execute('123-456') }.to raise_exception(UseCase::FetchDomesticEpc::NotFoundException)
    end
  end
end
