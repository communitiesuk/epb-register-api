RSpec.describe Worker::ExportInvoices do
  describe "#perform" do
    let(:use_case) { instance_double(UseCase::GetAssessmentCountBySchemeNameAndType) }
    let(:returned_data) { [{ type_of_assessment: "AC-CERT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 2 }, { type_of_assessment: "AC-REPORT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 3 }] }

    before do
      Timecop.freeze(2022, 9, 1, 0, 0, 0)
      WebMock.enable!
      WebMock.stub_request(:post, "https://slack.com/api/files.upload").to_return(status: 200, headers: {})
      allow(ApiFactory).to receive(:get_assessment_count_by_scheme_name_type).and_return(use_case)
      allow(use_case).to receive(:execute).and_return returned_data
    end

    after do
      Timecop.return
    end

    it "executes the rake which calls the use case" do
      expect { described_class.new.perform }.not_to raise_error
    end

    it "executes the rake which calls the subsequent export code" do
      described_class.new.perform
      expect(use_case).to have_received(:execute).with("2022-08-01".to_date, "2022-09-01".to_date).exactly(1).times
    end
  end
end
