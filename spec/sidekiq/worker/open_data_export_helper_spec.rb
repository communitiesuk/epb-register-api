require_relative "../../acceptance/reporting/open_data_export_test_helper"

describe Worker::OpenDataExportHelper do
  include RSpecRegisterApiServiceMixin

  before do
    Timecop.freeze(2022, 9, 1, 7, 0, 0)
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
          Date.yesterday.strftime("%Y-%m-30"),
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
          Date.yesterday.strftime("%Y-%m-30"),
        )
      lodge_assessment(
        assessment_body: domestic_rdsap_xml.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
      )

      ActiveRecord::Base.connection.exec_query("UPDATE Assessments SET created_at='2022-08-30 12:35:26'")

      EnvironmentStub
        .all.with("OPEN_DATA_REPORT_TYPE", "not_for_odc")

      stub_request(:put, "https://s3.eu-west-2.amazonaws.com/test_bucket/test/open_data_export_sap-rdsap_2022-09-01_1.csv")
        .to_return(status: 200, body: "", headers: {})
    end

    it "executes the rake which calls the use case" do
      expect { described_class.call_rake(assessment_types: "SAP-RDSAP") }.not_to raise_error
    end

    it "sends the file to the S3 bucket" do
      described_class.call_rake(assessment_types: "SAP-RDSAP")
      expect(WebMock).to have_requested(
        :put,
        "https://s3.eu-west-2.amazonaws.com/test_bucket/test/open_data_export_sap-rdsap_2022-09-01_1.csv",
      )
    end

    context "when calling the rake method twice" do
      it "call two different rakes" do
        described_class.call_rake(assessment_types: "SAP-RDSAP")
        expect { described_class.call_rake(assessment_types: "DEC") }.to raise_error(Boundary::OpenDataEmpty)
      end
    end

    context "when calling the rake to run data into the live folder" do
      before do
        EnvironmentStub
          .all.with("OPEN_DATA_REPORT_TYPE", "for_odc")
        stub_request(:put, "https://s3.eu-west-2.amazonaws.com/test_bucket/open_data_export_sap-rdsap_2022-09-01_1.csv")
          .to_return(status: 200, body: "", headers: {})

        described_class.call_rake(assessment_types: "SAP-RdSAP")
      end

      it "sends the not for publication file to the S3 bucket" do
        expect(WebMock).to have_requested(
          :put,
          "https://s3.eu-west-2.amazonaws.com/test_bucket/open_data_export_sap-rdsap_2022-09-01_1.csv",
        )
      end
    end

    context "when calling the rake to run not for publication" do
      before do
        ActiveRecord::Base.connection.exec_query("UPDATE assessments SET cancelled_at= '2022-08-31' WHERE assessment_id='0000-0000-0000-0000-1004'")
      end

      it "sends the not for publication file to the live S3 bucket" do
        EnvironmentStub
          .all.with("OPEN_DATA_REPORT_TYPE", "for_odc")

        stub_request(:put, "https://s3.eu-west-2.amazonaws.com/test_bucket/open_data_export_not_for_publication_2022-09-01.csv")
          .to_return(status: 200, body: "", headers: {})
        described_class.call_rake(rake_name: "open_data:export_not_for_publication")
        expect(WebMock).to have_requested(
          :put,
          "https://s3.eu-west-2.amazonaws.com/test_bucket/open_data_export_not_for_publication_2022-09-01.csv",
        )
      end

      it "sends the not for publication file to the test S3 bucket" do
        EnvironmentStub
          .all.with("OPEN_DATA_REPORT_TYPE", "not_for_odc")

        stub_request(:put, "https://s3.eu-west-2.amazonaws.com/test_bucket/test/open_data_export_not_for_publication_2022-09-01.csv")
          .to_return(status: 200, body: "", headers: {})
        described_class.call_rake(rake_name: "open_data:export_not_for_publication")
        expect(WebMock).to have_requested(
          :put,
          "https://s3.eu-west-2.amazonaws.com/test_bucket/test/open_data_export_not_for_publication_2022-09-01.csv",
        )
      end
    end
  end
end
