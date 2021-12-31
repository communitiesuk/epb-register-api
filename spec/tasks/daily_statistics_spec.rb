describe "daily statistics rake" do
  let(:daily_statistics_rake) { get_task("maintenance:daily_statistics") }

  let(:save_daily_assessments_stats_use_case) { instance_double(UseCase::SaveDailyAssessmentsStats) }

  before do
    allow($stdout).to receive(:puts)
    allow(ApiFactory).to receive(:save_daily_assessments_stats_use_case).and_return(save_daily_assessments_stats_use_case)
    allow(save_daily_assessments_stats_use_case).to receive(:execute)
  end

  it "calls the use case to save yesterday data by default and prints success message" do
    yesterday = (Time.now.to_date - 1).strftime("%F")
    expect { daily_statistics_rake.invoke }.to output(
      /Statistics for #{yesterday} saved/,
    ).to_stdout
    expect(save_daily_assessments_stats_use_case).to have_received(:execute).with(
      date: yesterday,
      assessment_types: %w[SAP RdSAP CEPC DEC AC-CERT DEC-RR],
    )
  end

  it "calls the use case to save the data for a given date and prints success message" do
    expect { daily_statistics_rake.invoke("2021-12-02") }.to output(
      /Statistics for 2021-12-02 saved/,
    ).to_stdout
    expect(save_daily_assessments_stats_use_case).to have_received(:execute).with(
      date: "2021-12-02",
      assessment_types: %w[SAP RdSAP CEPC DEC AC-CERT DEC-RR],
    )
  end

  it "raises an error for an invalid date" do
    expect { daily_statistics_rake.invoke("2021-01-35") }.to raise_error(ArgumentError)
    expect { daily_statistics_rake.invoke("20-01-2021") }.to raise_error(ArgumentError)
  end
end
