describe "back full daily statistics rake" do
  let(:back_fill_statistics) { get_task("maintenance:back_fill_statistics") }
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

  context "when invoking a rake without arguments" do
    it "raise and argument error" do
      expect { back_fill_statistics.invoke }.to raise_error(Boundary::ArgumentMissing)
    end
  end

  context "when invoking the rake with correct argument " do
    it "calls the use case to export daily assessments 5 times" do
      assessment_types = %w[SAP RdSAP CEPC DEC DEC-RR AC-CERT]
      back_fill_statistics.invoke(5)
      expect(save_daily_assessments_stats_use_case).to have_received(:execute).exactly(5).times
      expect(save_daily_assessments_stats_use_case).to have_received(:execute).with(date: (Time.now.to_date - 3).strftime("%F"), assessment_types: assessment_types).exactly(1).times
    end
  end
end
