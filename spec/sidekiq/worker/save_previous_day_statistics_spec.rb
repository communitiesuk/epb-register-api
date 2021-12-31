RSpec.describe Worker::SavePreviousDayStatistics do
  before { allow($stdout).to receive(:puts) }

  it "invokes the rake task" do
    expect { described_class.new.perform }.not_to raise_error
  end
end

