describe "daily statistics rake" do
  let(:daily_statistics_rake) { get_task("maintenance:daily_statistics").invoke }
  let(:assessments_gateway) { instance_double(Gateway::AssessmentsGateway) }
  let(:assessments_xml_gateway) { instance_double(Gateway::AssessmentsXmlGateway) }
  let(:save_daily_assessments_stats_use_case) { instance_double(UseCase::SaveDailyAssessmentsStats) }

  before do
    allow($stdout).to receive(:puts)
    allow(ApiFactory).to receive(:assessments_gateway).and_return(assessments_gateway)
    allow(ApiFactory).to receive(:assessments_xml_gateway).and_return(assessments_xml_gateway)
    allow(ApiFactory).to receive(:save_daily_assessments_stats_use_case).and_return(save_daily_assessments_stats_use_case)
    allow(save_daily_assessments_stats_use_case).to receive(:execute)
  end

  it "calls the use case to save the data and prints success message" do
    allow(assessments_gateway).to receive(:fetch_assessments_by_date).and_return([
      { "assessment_id" => "0000-0000-0000-0000", "assessment_type" => "RdSAP", "scheme_id": 1 },
    ])
    rdsap_xml = Nokogiri.XML Samples.xml("RdSAP-Schema-20.0.0")
    allow(assessments_xml_gateway).to receive(:fetch).with("0000-0000-0000-0000").and_return({ "xml" => rdsap_xml, "schema_type" => "RdSAP-Schema-20.0.0" })

    yesterday = (Time.now.to_date - 1).strftime("%F")

    expect { daily_statistics_rake }.to output(
      /Statistics for #{yesterday} saved/,
    ).to_stdout
    expect(save_daily_assessments_stats_use_case).to have_received(:execute).with(
      date: yesterday,
      assessment_types: %w[SAP RdSAP CEPC],
    )
  end

  it "prints that there is no assessment data to save" do
    allow(assessments_gateway).to receive(:fetch_assessments_by_date).and_return([])
    allow(save_daily_assessments_stats_use_case).to receive(:execute).and_raise(UseCase::SaveDailyAssessmentsStats::NoDataException)

    expect { daily_statistics_rake }.to output(
      /No data to be saved/,
    ).to_stdout
  end
end
