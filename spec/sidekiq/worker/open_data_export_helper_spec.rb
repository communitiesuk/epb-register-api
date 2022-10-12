require_relative "../../acceptance/reporting/open_data_export_test_helper"

describe Worker::OpenDataExportHelper do
  include RSpecRegisterApiServiceMixin

  before do
    Timecop.freeze(2022, 9, 1, 0, 0, 0)
    WebMock.enable!
  end

  after do
    Timecop.return
    WebMock.disable!
  end

  describe "#get_last_months_methods" do
    it "returns the correct dates" do
      expect(described_class.get_last_months_dates).to be_a(Hash)
      expect(described_class.get_last_months_dates[:start_date]).to eq "2022-08-01"
      expect(described_class.get_last_months_dates[:end_date]).to eq "2022-09-01"
    end
  end

  describe "#call_rake" do
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
      expect { described_class.call_rake("SAP-RDSAP") }.not_to raise_error
    end

    it "sends the file to the S3 bucket" do
      described_class.call_rake("SAP-RDSAP")
      expect(WebMock).to have_requested(
        :put,
        "https://s3.eu-west-2.amazonaws.com/test_bucket/test/open_data_export_sap-rdsap_2022-09-01_1.csv",
      )
    end

    context "when calling the call rake method twice" do
      it "call two different rakes" do
        described_class.call_rake("SAP-RDSAP")
        expect { described_class.call_rake("DEC") }.to raise_error(Boundary::OpenDataEmpty)
      end
    end
  end
end
