describe "monthly invoice export" do
  let(:monthly_invoice_rake) { get_task("data_export:export_invoices") }

  context "when two arguments are passed to the rake" do
    before do
      WebMock.enable!
      WebMock.stub_request(:post, "https://slack.com/api/files.upload").to_return(status: 200, headers: {}, body: { ok: true }.to_json)
    end

    context "when invalid date range is passed " do
      it "raises a no data error" do
        expect { monthly_invoice_rake.invoke("22-08-01", "21-08-31", "scheme_name_type") }.to raise_error Boundary::NoData, "no data to be saved for: get assessment count by scheme name and type"
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
end
