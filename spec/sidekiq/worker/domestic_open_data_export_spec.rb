require_relative "../../acceptance/reporting/open_data_export_test_helper"
require "sentry-ruby"

RSpec.describe Worker::DomesticOpenDataExport do
  include RSpecRegisterApiServiceMixin

  describe "#perform" do
    before do
      Timecop.freeze(2022, 9, 1, 0, 0, 0)
      WebMock.enable!
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
        allow(Sentry).to receive(:capture_exception)
      end

      it "send the error to sentry" do
        described_class.new.perform
        expect(Sentry).to have_received(:capture_exception).with(Boundary::OpenDataEmpty).exactly(1).times
      end
    end
  end
end
