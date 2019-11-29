class StubToggles
  def toggles; end

  def state(name)
    name == 'a'
  end
end

describe AssessorService do
  let(:subject) { described_class.new(StubToggles.new).helpers }

  it 'is a' do
    described_class.new

    expect(subject.toggles.state('a')).to eq(true)
  end

  it 'is not b' do
    expect(subject.toggles.state('b')).to eq(false)
  end
end
