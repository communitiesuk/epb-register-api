describe UseCase::FetchSchemes do
  class SchemesGatewayFake
    attr_writer :schemes

    def initialize
      @schemes = {}
    end

    def all
      @schemes
    end
  end

  let(:schemes_gateway) { SchemesGatewayFake.new }

  let(:response) { described_class.new(schemes_gateway).execute }

  context 'when there are no schemes' do
    it 'displays an empty hash' do
      expect(response).to eq(schemes: {})
    end
  end

  context 'when there are schemes' do
    it 'displays the schemes in a hash' do
      schemes_gateway.schemes = { name: 'hello' }

      expect(response).to eq(schemes: { name: 'hello' })
    end
  end
end
