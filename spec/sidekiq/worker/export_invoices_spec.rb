require "sentry-ruby"

RSpec.describe Worker::ExportInvoices do
  before do
    Timecop.freeze(2022, 9, 1, 0, 0, 0)
    WebMock.enable!
  end

  after do
    Timecop.return
  end

  describe "#perform" do
    let(:scheme_use_case) { instance_double(UseCase::GetAssessmentCountBySchemeNameAndType) }
    let(:region_use_case) { instance_double(UseCase::GetAssessmentCountByRegionAndType) }
    let(:rrn_use_case) { instance_double(UseCase::GetAssessmentRrnsBySchemeNameAndType) }
    let(:fetch_active_schemes_use_case) { instance_double(UseCase::FetchActiveSchemesId) }
    let(:returned_data) { [{ type_of_assessment: "AC-CERT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 2 }, { type_of_assessment: "AC-REPORT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 3 }] }
    let(:active_scheme_ids) { [1, 2, 3, 4, 5, 6, 18] }

    before do
      WebMock.stub_request(:post, "https://slack.com/api/files.upload").to_return(status: 200, headers: {}, body: { ok: true }.to_json)
      allow(ApiFactory).to receive(:get_assessment_count_by_scheme_name_type).and_return(scheme_use_case)
      allow(ApiFactory).to receive(:get_assessment_count_by_region_type).and_return(region_use_case)
      allow(ApiFactory).to receive(:get_assessment_rrns_by_scheme_type).and_return(rrn_use_case)
      allow(ApiFactory).to receive(:fetch_active_schemes_use_case).and_return(fetch_active_schemes_use_case)
      allow(scheme_use_case).to receive(:execute).and_return returned_data
      allow(region_use_case).to receive(:execute).and_return returned_data
      allow(rrn_use_case).to receive(:execute).and_return returned_data
      allow(fetch_active_schemes_use_case).to receive(:execute).and_return active_scheme_ids
      allow(Sentry).to receive(:capture_exception)
    end

    it "executes the rake which calls the use case" do
      expect { described_class.new.perform }.not_to raise_error
    end

    it "executes the rake which calls the subsequent export code" do
      described_class.new.perform
      expect(scheme_use_case).to have_received(:execute).with("2022-08-01".to_date, "2022-09-01".to_date).exactly(1).times
      expect(region_use_case).to have_received(:execute).with("2022-08-01".to_date, "2022-09-01".to_date).exactly(1).times
    end

    it "call the rake many times for each scheme" do
      described_class.new.perform
      (1..6).each { |i| expect(rrn_use_case).to have_received(:execute).with("2022-08-01".to_date, "2022-09-01".to_date, i).exactly(1).times }
      expect(rrn_use_case).to have_received(:execute).with("2022-08-01".to_date, "2022-09-01".to_date, 18).exactly(1).times
    end

    context "when the worker is run in the middle of the month" do
      before do
        Timecop.freeze(2023, 1, 15, 0, 0, 0)
        WebMock.enable!
      end

      after do
        Timecop.return
      end

      it "gets last months data" do
        described_class.new.perform
        expect(scheme_use_case).to have_received(:execute).with("2022-12-01".to_date, "2023-01-01".to_date).exactly(1).times
      end
    end

    context "when there is no data to send" do
      let(:use_case) { instance_double(UseCase::GetAssessmentCountBySchemeNameAndType) }

      before do
        allow(ApiFactory).to receive(:get_assessment_count_by_scheme_name_type).and_return(use_case)
        allow(use_case).to receive(:execute).and_return []
      end

      it "send the error to sentry" do
        described_class.new.perform
        expect(Sentry).to have_received(:capture_exception).with(Boundary::NoData).exactly(9).times
      end
    end

    context "when file cannot be uploaded to slack" do
      before do
        WebMock.stub_request(:post, "https://slack.com/api/files.upload").to_return(status: 200, headers: {}, body: { ok: false }.to_json)
      end

      it "send the errors to sentry" do
        described_class.new.perform
        expect(Sentry).to have_received(:capture_exception).with(Boundary::SlackMessageError).exactly(9).times
      end
    end
  end
end
