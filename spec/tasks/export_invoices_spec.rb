require "sentry-ruby"

describe "monthly invoice export" do
  let(:monthly_invoice_rake) { get_task("data_export:export_invoices") }

  context "when two arguments are passed to the rake" do
    before do
      WebMock.enable!
      WebMock.stub_request(:post, "https://slack.com/api/files.upload").to_return(status: 200, headers: {}, body: { ok: true }.to_json)
    end

    context "when invalid date range is passed " do
      it "raises a no data error" do
        expect { monthly_invoice_rake.invoke("22-08-01", "21-08-31", "scheme_name_type") }.to raise_error Boundary::NoData, "no data to be saved for: get assessment count by scheme name and type scheme_name_type"
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

      it "posts the csv to slack" do
        monthly_invoice_rake.invoke("22-08-01", "22-08-31", "scheme_name_type")
        expect(WebMock).to have_requested(
          :post,
          "https://slack.com/api/files.upload",
        ).with(headers: { "Content-Type" => %r{multipart/form-data} })
      end

      it "deletes the generated csv file" do
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

      it "posts the csv to slack" do
        monthly_invoice_rake.invoke("22-08-01", "22-08-31", "region_type")
        expect(WebMock).to have_requested(
          :post,
          "https://slack.com/api/files.upload",
        ).with(headers: { "Content-Type" => %r{multipart/form-data} })
      end

      it "deletes the generated csv file" do
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

      it "posts the csv to slack" do
        monthly_invoice_rake.invoke("22-08-01", "22-08-31", "rrn_scheme_type", 1)
        expect(WebMock).to have_requested(
          :post,
          "https://slack.com/api/files.upload",
        ).with(headers: { "Content-Type" => %r{multipart/form-data} })
      end

      it "deletes the generated csv file" do
        expect(File.exist?("rrn_scheme_type_1_invoice_report.csv")).to be false
      end

      it "deletes the generated zip file" do
        expect(File.exist?("rrn_scheme_type_1_invoice.zip")).to be false
      end
    end
  end

  context "when passing environmental variables to the rake" do
    before do
      WebMock.enable!
      WebMock.stub_request(:post, "https://slack.com/api/files.upload").to_return(status: 200, headers: {}, body: { ok: true }.to_json)
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

  context "when posting to slack fails" do
    let(:use_case) { instance_double(UseCase::GetAssessmentCountByRegionAndType) }
    let(:returned_data) { [{ number_of_assessments: 122, type_of_assessment: "AC-CERT", region: "Eastern" }, { number_of_assessments: 153, type_of_assessment: "CEPC", region: "Northern Ireland " }] }

    before do
      allow(ApiFactory).to receive(:get_assessment_count_by_scheme_name_type).and_return(use_case)
      allow(use_case).to receive(:execute).and_return returned_data
      WebMock.enable!
    end

    it "raises a boundary error message with bad json" do
      WebMock.stub_request(:post, "https://slack.com/api/files.upload").to_return(status: 200, body: { ok: false }.to_json)
      expect { monthly_invoice_rake.invoke("22-08-01", "22-08-31", "scheme_name_type") }.to raise_error Boundary::SlackMessageError
    end

    it "raises a boundary error message with no data" do
      WebMock.stub_request(:post, "https://slack.com/api/files.upload").to_return(status: 500, body: {
        ok: false,
        error: "unknown_method",
      }.to_json)
      expect { monthly_invoice_rake.invoke("22-08-01", "22-08-31", "scheme_name_type") }.to raise_error Boundary::SlackMessageError
    end

    it "deletes the generated csv file" do
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
      EnvironmentStub.with("scheme_id", "1")
      allow(ApiFactory).to receive(:get_assessment_count_by_scheme_name_type).and_return(use_case)
      allow(use_case).to receive(:execute).and_return returned_data
      allow(Helper::ExportInvoicesHelper).to receive(:save_file)
      allow(Helper::ExportInvoicesHelper).to receive(:send_to_slack)
      monthly_invoice_rake.invoke
    end

    after do
      Timecop.return
      EnvironmentStub.remove(%w[report_type scheme_id])
    end

    it "passes this month's start and end dates to the use case" do
      expect(use_case).to have_received(:execute).with(Date.parse("2024-01-01"), Date.parse("2024-02-01"))
    end
  end

  context "when calling rake:export_schema_invoices" do
    let(:monthly_invoice_rake) { get_task("data_export:export_schema_invoices") }
    let(:use_case) { instance_double(UseCase::GetAssessmentRrnsBySchemeNameAndType) }
    let(:fetch_active_schemes_use_case) { instance_double(UseCase::FetchActiveSchemesId) }
    let(:active_scheme_ids) { [1, 2, 3] }
    let(:rrn_use_case1) { instance_double(UseCase::GetAssessmentRrnsBySchemeNameAndType) }
    let(:rrn_use_case2) { instance_double(UseCase::GetAssessmentRrnsBySchemeNameAndType) }
    let(:rrn_use_case3) { instance_double(UseCase::GetAssessmentRrnsBySchemeNameAndType) }
    let(:returned_data) { [{ type_of_assessment: "AC-CERT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 2 }, { type_of_assessment: "AC-REPORT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 3 }] }

    before do
      Timecop.freeze(2024, 2, 1, 0, 0, 0)
      WebMock.enable!
      WebMock.stub_request(:post, "https://slack.com/api/files.upload").to_return(status: 200, headers: {}, body: { ok: true }.to_json)
      allow(ApiFactory).to receive(:get_assessment_rrns_by_scheme_type).and_return(rrn_use_case1, rrn_use_case2, rrn_use_case3)
      allow(ApiFactory).to receive(:fetch_active_schemes_use_case).and_return(fetch_active_schemes_use_case)
      allow(rrn_use_case1).to receive(:execute).with("2024-01-01".to_date, "2024-02-01".to_date, 1).and_return returned_data
      allow(rrn_use_case2).to receive(:execute).with("2024-01-01".to_date, "2024-02-01".to_date, 2).and_return []
      allow(rrn_use_case3).to receive(:execute).with("2024-01-01".to_date, "2024-02-01".to_date, 3).and_return returned_data
      allow(fetch_active_schemes_use_case).to receive(:execute).and_return active_scheme_ids
      allow(Sentry).to receive(:capture_exception)

      monthly_invoice_rake.invoke
    end

    after do
      Timecop.return
      WebMock.disable!
    end

    it "exports schemas with data" do
      expect(rrn_use_case1).to have_received(:execute).with("2024-01-01".to_date, "2024-02-01".to_date, 1).exactly(1).times
      expect(rrn_use_case2).to have_received(:execute).with("2024-01-01".to_date, "2024-02-01".to_date, 2).exactly(1).times
      expect(rrn_use_case3).to have_received(:execute).with("2024-01-01".to_date, "2024-02-01".to_date, 3).exactly(1).times
    end

    it "send a no data error to sentry for one of the schemas" do
      expect(Sentry).to have_received(:capture_exception).with(Boundary::NoData).exactly(1).times
    end
  end
end
