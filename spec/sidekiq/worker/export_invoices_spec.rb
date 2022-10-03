RSpec.describe Worker::ExportInvoices do
  before do
    Timecop.freeze(2022, 9, 1, 0, 0, 0)
    WebMock.enable!
  end

  after do
    Timecop.return
  end

  describe "#perform" do
    let(:use_case) { instance_double(UseCase::GetAssessmentCountBySchemeNameAndType) }
    let(:returned_data) { [{ type_of_assessment: "AC-CERT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 2 }, { type_of_assessment: "AC-REPORT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 3 }] }

    before do
      WebMock.stub_request(:post, "https://slack.com/api/files.upload").to_return(status: 200, headers: {}, body: { ok: true }.to_json)
      allow(ApiFactory).to receive(:get_assessment_count_by_scheme_name_type).and_return(use_case)
      allow(use_case).to receive(:execute).and_return returned_data
    end

    it "executes the rake which calls the use case" do
      expect { described_class.new.perform }.not_to raise_error
    end

    it "executes the rake which calls the subsequent export code" do
      described_class.new.perform
      expect(use_case).to have_received(:execute).with("2022-08-01".to_date, "2022-09-01".to_date).exactly(1).times
    end

    context "when there is no data to send" do
      let(:use_case) { instance_double(UseCase::GetAssessmentCountBySchemeNameAndType) }
      let(:returned_data) { [{ type_of_assessment: "AC-CERT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 2 }, { type_of_assessment: "AC-REPORT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 3 }] }

      before do
        allow(Worker::SlackNotification).to receive(:perform_async)
        allow(ApiFactory).to receive(:get_assessment_count_by_scheme_name_type).and_return(use_case)
        allow(use_case).to receive(:execute).and_return []
      end

      it "post the error to slack" do
        described_class.new.perform
        expect(Worker::SlackNotification).to have_received(:perform_async).with(/No data for invoice report: scheme_name_type /).exactly(1).times
      end
    end

    context "when data cannot be posted to slack" do
      let(:use_case) { instance_double(UseCase::GetAssessmentCountBySchemeNameAndType) }
      let(:returned_data) { [{ type_of_assessment: "AC-CERT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 2 }, { type_of_assessment: "AC-REPORT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 3 }] }

      before do
        allow(Worker::SlackNotification).to receive(:perform_async)
        allow(ApiFactory).to receive(:get_assessment_count_by_scheme_name_type).and_return(use_case)
        allow(use_case).to receive(:execute).and_return returned_data
        WebMock.stub_request(:post, "https://slack.com/api/files.upload").to_return(status: 200, headers: {}, body: { ok: false }.to_json)
      end

      it "post the error to slack" do
        described_class.new.perform
        expect(Worker::SlackNotification).to have_received(:perform_async).with(/Unable to post invoice report to slack: scheme_name_type/).exactly(1).times
      end
    end
  end
end
