describe Gateway::SchemesGateway do
  context 'when adding a scheme' do
    it 'can add a scheme' do
      expect(Gateway::SchemesGateway::Scheme).to receive(:create)

      subject = described_class.new
      subject.add('test')
    end
  end

  context 'when there are no schemes' do
    it 'can show an empty hash' do
      allow(Gateway::SchemesGateway::Scheme).to receive(:all).and_return({})

      expect(Gateway::SchemesGateway::Scheme).to receive(:all)

      subject = described_class.new
      subject.all
    end
  end

  context 'when there are schemes' do
    it 'can show results' do
      allow(Gateway::SchemesGateway::Scheme).to receive(:all).and_return([{ id: 1, name: 'hello' }])

      expect(described_class.new.all).to eq([{ scheme_id: 1, name: 'hello' }])
    end
  end
end
