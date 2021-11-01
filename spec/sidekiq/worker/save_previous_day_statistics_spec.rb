RSpec.describe Worker::SavePreviousDayStatistics do
  before { allow($stdout).to receive(:puts) }

  it "invokes the rake task" do
    expect { described_class.new.perform }.not_to raise_error
  end

  it "prints that couldn't calculate statistics if there were no assessments lodged" do
    expect { described_class.new.perform }.to output(
      /No assessments lodged yesterday to calculate statistics/,
    ).to_stdout
  end
end
