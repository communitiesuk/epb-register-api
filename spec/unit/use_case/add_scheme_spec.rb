describe UseCase::AddScheme do
  class SchemesGatewaySpy
    def add(*)
      @add_was_called = true
    end

    def add_was_called?
      @add_was_called
    end
  end

  let(:schemes_gateway) { SchemesGatewaySpy.new }
  let!(:response) { described_class.new(schemes_gateway).execute('name') }

  context 'when adding a scheme' do
    it 'checks if add was called' do
      expect(schemes_gateway.add_was_called?).to be true
    end
  end
end
