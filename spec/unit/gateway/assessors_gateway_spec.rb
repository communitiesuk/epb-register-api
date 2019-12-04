describe Gateway::AssessorsGateway do
  context 'when adding an assessor' do
    it 'can add an assessor' do
      expect(Gateway::AssessorsGateway::Assessor).to receive(:create)

      subject = described_class.new
      subject.update('SCHE4321', 10, {})
    end
  end
end
