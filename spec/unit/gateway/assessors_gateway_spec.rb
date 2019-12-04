describe Gateway::AssessorsGateway do
  context 'when adding an assessor' do
    it 'can add an assessor' do
      expect(Gateway::AssessorsGateway::Assessor).to receive(:create)

      subject = described_class.new
      subject.update('SCHE4321', 10, {})
    end
  end

  context 'when there are no assessors' do
    it 'can return nil' do
      allow(Gateway::AssessorsGateway::Assessor).to receive(:find_by)
        .and_return(nil)

      expect(Gateway::AssessorsGateway::Assessor).to receive(:find_by).with(
        scheme_assessor_id: 'SCHE1234'
      )

      subject = described_class.new
      expect(subject.fetch('SCHE1234')).to eq(nil)
    end
  end

  context 'when there are assessors' do
    it 'can show results' do
      allow(Gateway::AssessorsGateway::Assessor).to receive(:find_by).with(
        scheme_assessor_id: 'SCHE5678'
      )
        .and_return([{ registered_by: 20, scheme_assessor_id: 'SCHE5678' }])

      expect(described_class.new.fetch('SCHE5678')).to eq(
        [{ registered_by: 20, scheme_assessor_id: 'SCHE5678' }]
      )
    end
  end
end
