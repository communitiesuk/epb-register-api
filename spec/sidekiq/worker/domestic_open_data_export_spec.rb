require_relative "../../acceptance/reporting/open_data_export_test_helper"

RSpec.describe Worker::DomesticOpenDataExport do
  include RSpecRegisterApiServiceMixin

  describe "#perform" do
    before do
      Timecop.freeze(2022, 9, 1, 0, 0, 0)
      WebMock.enable!
      WebMock.stub_request(:post, "https://slack.com/api/files.upload").to_return(status: 200, headers: {}, body: { ok: true }.to_json)
      allow(Worker::SlackNotification).to receive(:perform_async)
      allow($stdout).to receive(:puts)
    end

    after do
      Timecop.return
      WebMock.disable!
    end

    context "when there is data to send" do
      before do
        scheme_id = lodge_assessor
        domestic_rdsap_xml =
          get_assessment_xml(
            "RdSAP-Schema-20.0.0",
            "0000-0000-0000-0000-0004",
            Date.yesterday.strftime("%Y-%m-%d"),
          )
        lodge_assessment(
          assessment_body: domestic_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )

        domestic_rdsap_xml =
          get_assessment_xml(
            "RdSAP-Schema-20.0.0",
            "0000-0000-0000-0000-1004",
            Date.yesterday.strftime("%Y-%m-%d"),
          )
        lodge_assessment(
          assessment_body: domestic_rdsap_xml.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          migrated: true,
        )

        EnvironmentStub
          .all

        stub_request(:put, "https://s3.eu-west-2.amazonaws.com/test_bucket/test/open_data_export_sap-rdsap_2022-09-01_1.csv")
          .to_return(status: 200, body: "", headers: {})
      end

      it "executes the rake which calls the use case" do
        expect { described_class.new.perform }.not_to raise_error
      end

      it "sends the file to the S3 bucket" do
        described_class.new.perform
        expect(WebMock).to have_requested(
          :put,
          "https://s3.eu-west-2.amazonaws.com/test_bucket/test/open_data_export_sap-rdsap_2022-09-01_1.csv",
        )
      end
    end

    context "when there is no data to send" do
      before do
        allow(Worker::SlackNotification).to receive(:perform_async)
      end

      it "runs the rake with the correct start and end date", :aggregate_failures do
        my_class = described_class.new
        my_class.perform
        expect(my_class.start_date).to eq("2022-08-01")
        expect(my_class.end_date).to eq("2022-09-01")
      end

      it "post the error to slack" do
        described_class.new.perform
        expect(Worker::SlackNotification).to have_received(:perform_async).with(/No data for domestic ODC Export/).exactly(1).times
      end
    end
  end
end
