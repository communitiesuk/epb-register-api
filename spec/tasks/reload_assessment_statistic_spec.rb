describe "ReloadAssessmentStatistics" do
  include RSpecRegisterApiServiceMixin
  let(:reload_task) { get_task("oneoff:reload_assessment_statistics") }

  let(:use_case) { instance_double(UseCase::ReloadAssessmentStatistics) }

  describe "when calling the rake" do
    before do
      allow(ApiFactory).to receive(:reload_assessment_statistics_use_case).and_return(use_case)
      allow(use_case).to receive(:execute)
    end

    it "calls the expected use case" do
      reload_task.invoke
      expect(use_case).to have_received(:execute).exactly(1).times
    end
  end
end
