require "sentry-ruby"
require "slack"

describe "monthly invoice export" do
  let(:monthly_invoice_rake) { get_task("data_export:export_invoices") }
  let(:slack_gateway) { instance_double(Gateway::SlackGateway) }
  let(:slack_web_client) { instance_double(Slack::Web::Client) }
  let(:slack_external_url_body) { { "upload_url" => "https://files.slack.com/upload/v1/Ad4FoJN1mC67CgACFF", "file_id" => "F07KB41F4P7", "ok" => true } }

  before do
    WebMock.enable!
    allow(ApiFactory).to receive(:slack_gateway).and_return(slack_gateway)
    allow(Gateway::SlackGateway).to receive(:new).and_return(slack_gateway)
    allow(slack_gateway).to receive_messages(upload_file: true, post_file: true)
    allow(slack_web_client).to receive_messages(files_getUploadURLExternal: slack_external_url_body, files_completeUploadExternal: true)
  end

  after do
    WebMock.disable!
    Timecop.return
  end

  context "when two arguments are passed to the rake" do
    context "when invalid date range is passed" do
      before do
        allow(Sentry).to receive(:capture_exception)
      end

      it "raises a no data error" do
        monthly_invoice_rake.invoke("22-08-01", "21-08-31", "scheme_name_type")
        expect(Sentry).to have_received(:capture_exception).with(Boundary::NoData).exactly(1).times
      end
    end

    context "when there is invoice data for get assessment count by scheme name and type" do
      let(:use_case) { instance_double(UseCase::GetAssessmentCountBySchemeNameAndType) }
      let(:returned_data) { [{ type_of_assessment: "AC-CERT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 2 }, { type_of_assessment: "AC-REPORT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 3 }] }

      before do
        allow(ApiFactory).to receive(:get_assessment_count_by_scheme_name_type).and_return(use_case)
        allow(use_case).to receive(:execute).and_return []
        allow(use_case).to receive(:execute).and_return returned_data
      end

      it "calls the expected use case" do
        monthly_invoice_rake.invoke("22-08-01", "22-08-31", "scheme_name_type")
        expect(use_case).to have_received(:execute).with(Date.parse("22-08-01"), Date.parse("22-08-31")).exactly(1).times
      end

      it "does not raise and error" do
        expect { monthly_invoice_rake.invoke("22-08-01", "22-08-31", "scheme_name_type") }.not_to raise_error
      end

      it "posts the CSV to Slack" do
        monthly_invoice_rake.invoke("22-08-01", "22-08-31", "scheme_name_type")
        expect(slack_gateway).to have_received(:upload_file).with(file_path: "scheme_name_type_invoice.zip", message: "test - Invoice report for August 2022 scheme_name_type").exactly(1).times
      end

      it "deletes the generated CSV file" do
        expect(File.exist?("scheme_name_type_invoice_report.csv")).to be false
      end

      it "deletes the generated zip file" do
        expect(File.exist?("scheme_name_type_invoice.zip")).to be false
      end
    end

    context "when there is invoice data for get assessment count by region and type" do
      let(:use_case) { instance_double(UseCase::GetAssessmentCountByRegionAndType) }
      let(:returned_data) { [{ number_of_assessments: 122, type_of_assessment: "AC-CERT", region: "Eastern" }, { number_of_assessments: 153, type_of_assessment: "CEPC", region: "Northern Ireland " }] }

      before do
        allow(ApiFactory).to receive(:get_assessment_count_by_region_type).and_return(use_case)
        allow(use_case).to receive(:execute).and_return []
        allow(use_case).to receive(:execute).and_return returned_data
      end

      it "calls the expected use case" do
        monthly_invoice_rake.invoke("22-08-01", "22-08-31", "region_type")
        expect(use_case).to have_received(:execute).with(Date.parse("22-08-01"), Date.parse("22-08-31")).exactly(1).times
      end

      it "does not raise and error" do
        expect { monthly_invoice_rake.invoke("22-08-01", "22-08-31", "region_type") }.not_to raise_error
      end

      it "posts the CSV to Slack" do
        monthly_invoice_rake.invoke("22-08-01", "22-08-31", "region_type")
        expect(slack_gateway).to have_received(:upload_file).exactly(1).times
      end

      it "deletes the generated CSV file" do
        expect(File.exist?("region_type_invoice_report.csv")).to be false
      end

      it "deletes the generated zip file" do
        expect(File.exist?("region_type_invoice.zip")).to be false
      end
    end

    context "when there is invoice data for get assessment rrns by scheme and type" do
      let(:use_case) { instance_double(UseCase::GetAssessmentRrnsBySchemeNameAndType) }
      let(:returned_data) do
        [{ rrn: "0000-0000-0000-0000-0000", scheme_name: "test", type_of_assessment: "RdSAP", lodged_at: "2022-08-01 00:20:33 UTC" },
         { rrn: "0000-0000-0000-0000-0001", scheme_name: "test", type_of_assessment: "RdSAP", lodged_at: "2022-08-02 00:20:33 UTC" }]
      end

      before do
        allow(ApiFactory).to receive(:get_assessment_rrns_by_scheme_type).and_return(use_case)
        allow(use_case).to receive(:execute).and_return []
        allow(use_case).to receive(:execute).and_return returned_data
      end

      it "calls the expected use case" do
        monthly_invoice_rake.invoke("22-08-01", "22-08-31", "rrn_scheme_type", 1)
        expect(use_case).to have_received(:execute).with(Date.parse("22-08-01"), Date.parse("22-08-31"), 1).exactly(1).times
      end

      it "does not raise and error" do
        expect { monthly_invoice_rake.invoke("22-08-01", "22-08-31", "rrn_scheme_type", 1) }.not_to raise_error
      end

      it "posts the CSV to Slack" do
        monthly_invoice_rake.invoke("22-08-01", "22-08-31", "rrn_scheme_type", 1)
        expect(slack_gateway).to have_received(:upload_file).exactly(1).times
      end

      it "deletes the generated CSV file" do
        expect(File.exist?("rrn_scheme_type_1_invoice_report.csv")).to be false
      end

      it "deletes the generated zip file" do
        expect(File.exist?("rrn_scheme_type_1_invoice.zip")).to be false
      end
    end
  end

  context "when passing environmental variables to the rake" do
    before do
      allow(ApiFactory).to receive_messages(get_assessment_count_by_scheme_name_type: use_case, slack_gateway:)
    end

    context "when getting the assessment count by scheme name and type" do
      let(:use_case) { instance_double(UseCase::GetAssessmentCountBySchemeNameAndType) }
      let(:returned_data) { [{ type_of_assessment: "AC-CERT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 2 }, { type_of_assessment: "AC-REPORT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 3 }] }

      before do
        allow(ApiFactory).to receive(:get_assessment_count_by_scheme_name_type).and_return(use_case)
        allow(use_case).to receive(:execute).and_return []
        allow(use_case).to receive(:execute).and_return returned_data
        EnvironmentStub.with("start_date", "2020-05-01")
        EnvironmentStub.with("end_date", "2020-05-31")
        EnvironmentStub.with("report_type", "scheme_name_type")
      end

      after do
        EnvironmentStub.remove(%w[start_date end_date report_type])
      end

      it "calls without error" do
        expect { monthly_invoice_rake.invoke }.not_to raise_error
      end
    end

    context "when getting the assessment count by region and type" do
      let(:use_case) { instance_double(UseCase::GetAssessmentCountByRegionAndType) }
      let(:returned_data) { [{ number_of_assessments: 122, type_of_assessment: "AC-CERT", region: "Eastern" }, { number_of_assessments: 153, type_of_assessment: "CEPC", region: "Northern Ireland " }] }

      before do
        allow(ApiFactory).to receive(:get_assessment_count_by_region_type).and_return(use_case)
        allow(use_case).to receive(:execute).and_return []
        allow(use_case).to receive(:execute).and_return returned_data
        EnvironmentStub.with("start_date", "2020-05-01")
        EnvironmentStub.with("end_date", "2020-05-31")
        EnvironmentStub.with("report_type", "region_type")
      end

      after do
        EnvironmentStub.remove(%w[start_date end_date report_type])
      end

      it "calls without error" do
        expect { monthly_invoice_rake.invoke }.not_to raise_error
      end
    end

    context "when getting the assessment rrns by scheme and type" do
      let(:use_case) { instance_double(UseCase::GetAssessmentRrnsBySchemeNameAndType) }
      let(:returned_data) do
        [{ rrn: "0000-0000-0000-0000-0000", scheme_name: "test", type_of_assessment: "RdSAP", lodged_at: "2022-08-01 00:20:33 UTC" },
         { rrn: "0000-0000-0000-0000-0001", scheme_name: "test", type_of_assessment: "RdSAP", lodged_at: "2022-08-02 00:20:33 UTC" }]
      end

      before do
        allow(ApiFactory).to receive(:get_assessment_rrns_by_scheme_type).and_return(use_case)
        allow(use_case).to receive(:execute).and_return []
        allow(use_case).to receive(:execute).and_return returned_data
        EnvironmentStub.with("start_date", "2020-05-01")
        EnvironmentStub.with("end_date", "2020-05-31")
        EnvironmentStub.with("report_type", "rrn_scheme_type")
        EnvironmentStub.with("scheme_id", "1")
      end

      after do
        EnvironmentStub.remove(%w[start_date end_date report_type scheme_id])
      end

      it "calls without error" do
        expect { monthly_invoice_rake.invoke }.not_to raise_error
      end
    end
  end

  context "when posting to Slack fails" do
    let(:use_case) { instance_double(UseCase::GetAssessmentCountByRegionAndType) }
    let(:returned_data) { [{ number_of_assessments: 122, type_of_assessment: "AC-CERT", region: "Eastern" }, { number_of_assessments: 153, type_of_assessment: "CEPC", region: "Northern Ireland " }] }

    before do
      allow(ApiFactory).to receive(:get_assessment_count_by_scheme_name_type).and_return(use_case)
      allow(use_case).to receive(:execute).and_return returned_data

      allow(slack_gateway).to receive(:post_file).and_raise Boundary::SlackMessageError
      allow(slack_gateway).to receive(:upload_file).and_raise Boundary::SlackMessageError
      allow(Sentry).to receive(:capture_exception)
      monthly_invoice_rake.invoke("22-08-01", "22-08-31", "scheme_name_type")
    end

    it "sends a message to sentry" do
      expect(Sentry).to have_received(:capture_exception).with(Boundary::SlackMessageError).exactly(1).times
    end

    it "deletes the generated CSV file" do
      expect(File.exist?("scheme_name_type_invoice_report.csv")).to be false
    end

    it "deletes the generated zip file" do
      expect(File.exist?("scheme_name_type_invoice.zip")).to be false
    end
  end

  context "when it is the 1st of the month and no dates are passed to the rake" do
    let(:use_case) { instance_double(UseCase::GetAssessmentCountBySchemeNameAndType) }
    let(:returned_data) { [{ type_of_assessment: "AC-CERT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 2 }, { type_of_assessment: "AC-REPORT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 3 }] }

    before do
      Timecop.freeze(2024, 2, 1, 7, 0, 0)
      EnvironmentStub.with("report_type", "scheme_name_type")
      allow(ApiFactory).to receive(:get_assessment_count_by_scheme_name_type).and_return(use_case)
      allow(use_case).to receive(:execute).and_return returned_data
      allow(Helper::ExportInvoicesHelper).to receive(:save_file)
      monthly_invoice_rake.invoke
    end

    after do
      EnvironmentStub.remove(%w[report_type])
      Timecop.return
    end

    it "passes this month's start and end dates to the use case" do
      expect(use_case).to have_received(:execute).with(Date.parse("2024-01-01"), Date.parse("2024-02-01"))
    end
  end

  context "when calling rake:export_schema_invoices on the start of the month" do
    let(:monthly_invoice_rake) { get_task("data_export:export_schema_invoices") }
    let(:use_case) { instance_double(UseCase::GetAssessmentRrnsBySchemeNameAndType) }
    let(:fetch_active_schemes_use_case) { instance_double(UseCase::FetchActiveSchemesId) }
    let(:active_scheme_ids) { [1, 2, 3] }
    let(:rrn_use_case_one) { instance_double(UseCase::GetAssessmentRrnsBySchemeNameAndType) }
    let(:rrn_use_case_two) { instance_double(UseCase::GetAssessmentRrnsBySchemeNameAndType) }
    let(:rrn_use_case_three) { instance_double(UseCase::GetAssessmentRrnsBySchemeNameAndType) }
    let(:returned_data) { [{ type_of_assessment: "AC-CERT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 2 }, { type_of_assessment: "AC-REPORT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 3 }] }

    before do
      Timecop.freeze(2024, 2, 1, 0, 0, 0)
      allow($stdout).to receive(:puts)
      allow(ApiFactory).to receive(:get_assessment_rrns_by_scheme_type).and_return(rrn_use_case_one, rrn_use_case_two, rrn_use_case_three)
      allow(ApiFactory).to receive(:fetch_active_schemes_use_case).and_return(fetch_active_schemes_use_case)
      allow(rrn_use_case_one).to receive(:execute).with("2024-01-01".to_date, "2024-02-01".to_date, 1).and_return returned_data
      allow(rrn_use_case_two).to receive(:execute).with("2024-01-01".to_date, "2024-02-01".to_date, 2).and_return []
      allow(rrn_use_case_three).to receive(:execute).with("2024-01-01".to_date, "2024-02-01".to_date, 3).and_return returned_data
      allow(fetch_active_schemes_use_case).to receive(:execute).and_return active_scheme_ids
      allow(Sentry).to receive(:capture_exception)
      monthly_invoice_rake.invoke
    end

    after do
      Timecop.return
    end

    it "exports schemas with data" do
      expect(rrn_use_case_one).to have_received(:execute).with("2024-01-01".to_date, "2024-02-01".to_date, 1).exactly(1).times
      expect(rrn_use_case_two).to have_received(:execute).with("2024-01-01".to_date, "2024-02-01".to_date, 2).exactly(1).times
      expect(rrn_use_case_three).to have_received(:execute).with("2024-01-01".to_date, "2024-02-01".to_date, 3).exactly(1).times
    end

    it "send a no data error to sentry for one of the schemas" do
      expect(Sentry).to have_received(:capture_exception).with(Boundary::NoData).exactly(1).times
    end
  end

  context "when calling rake:export_schema_invoices with ENV variables" do
    let(:monthly_invoice_rake) { get_task("data_export:export_schema_invoices") }
    let(:use_case) { instance_double(UseCase::GetAssessmentRrnsBySchemeNameAndType) }
    let(:fetch_active_schemes_use_case) { instance_double(UseCase::FetchActiveSchemesId) }
    let(:active_scheme_ids) { [1, 2, 3] }
    let(:rrn_use_case_one) { instance_double(UseCase::GetAssessmentRrnsBySchemeNameAndType) }
    let(:rrn_use_case_two) { instance_double(UseCase::GetAssessmentRrnsBySchemeNameAndType) }
    let(:rrn_use_case_three) { instance_double(UseCase::GetAssessmentRrnsBySchemeNameAndType) }
    let(:returned_data) { [{ type_of_assessment: "AC-CERT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 2 }, { type_of_assessment: "AC-REPORT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 3 }] }

    before do
      EnvironmentStub.with("start_date", "2024-03-01")
      EnvironmentStub.with("end_date",   "2024-04-01")
      allow($stdout).to receive(:puts)
      allow(ApiFactory).to receive(:get_assessment_rrns_by_scheme_type).and_return(rrn_use_case_one, rrn_use_case_two, rrn_use_case_three)
      allow(ApiFactory).to receive(:fetch_active_schemes_use_case).and_return(fetch_active_schemes_use_case)
      allow(rrn_use_case_one).to receive(:execute).with("2024-03-01".to_date, "2024-04-01".to_date, 1).and_return returned_data
      allow(rrn_use_case_two).to receive(:execute).with("2024-03-01".to_date, "2024-04-01".to_date, 2).and_return []
      allow(rrn_use_case_three).to receive(:execute).with("2024-03-01".to_date, "2024-04-01".to_date, 3).and_return returned_data
      allow(fetch_active_schemes_use_case).to receive(:execute).and_return active_scheme_ids
      allow(Sentry).to receive(:capture_exception)
      monthly_invoice_rake.invoke
    end

    after do
      EnvironmentStub.remove(%w[start_date end_date report_type])
    end

    it "exports schemas with data" do
      expect(rrn_use_case_one).to have_received(:execute).with("2024-03-01".to_date, "2024-04-01".to_date, 1).exactly(1).times
      expect(rrn_use_case_two).to have_received(:execute).with("2024-03-01".to_date, "2024-04-01".to_date, 2).exactly(1).times
      expect(rrn_use_case_three).to have_received(:execute).with("2024-03-01".to_date, "2024-04-01".to_date, 3).exactly(1).times
    end

    it "send a no data error to sentry for one of the schemas" do
      expect(Sentry).to have_received(:capture_exception).with(Boundary::NoData).exactly(1).times
    end
  end
end
