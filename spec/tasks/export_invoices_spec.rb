describe "monthly invoice export" do
  let(:monthly_invoice_rake) { get_task("data_export:export_invoices") }

  context "when two arguments are passed to the rake" do
    before do
      WebMock.enable!
      WebMock.stub_request(:post, "https://slack.com/api/files.upload").to_return(status: 200, headers: {})
    end

    context "when invalid date range is passed " do
      it "raises a no data error" do
        expect { monthly_invoice_rake.invoke("22-08-01", "21-08-31", "schema_name_type") }.to raise_error Boundary::NoData, "no data to be saved for: get assessment count by scheme name and type"
      end
    end

    context "when there is invoice data for get assessment count by scheme name and type" do
      let(:use_case) { instance_double(UseCase::GetAssessmentCountBySchemeNameAndType) }
      let(:returned_data) { [{ type_of_assessment: "AC-CERT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 2 }, { type_of_assessment: "AC-REPORT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 3 }] }

      before do
        allow(ApiFactory).to receive(:get_assessment_count_by_scheme_name_type).and_return(use_case)
        allow(use_case).to receive(:execute).and_return []
        allow(use_case).to receive(:execute).and_return returned_data
        allow(ENV).to receive(:[])
      end

      it "calls the expected use case" do
        monthly_invoice_rake.invoke("22-08-01", "22-08-31", "schema_name_type")
        expect(use_case).to have_received(:execute).with(Date.parse("22-08-01"), Date.parse("22-08-31")).exactly(1).times
      end

      it "does not raise and error" do
        expect { monthly_invoice_rake.invoke("22-08-01", "22-08-31", "schema_name_type") }.not_to raise_error
      end

      it "posts the csv to slack" do
        monthly_invoice_rake.invoke("22-08-01", "22-08-31", "schema_name_type")
        expect(WebMock).to have_requested(
          :post,
          "https://slack.com/api/files.upload",
        ).with(headers: { "Content-Type" => %r{multipart/form-data} })
      end

      it "deletes the generated csv file" do
        expect(File.exist?("invoice_report.csv")).to be false
      end

      it "deletes the generated zip file" do
        expect(File.exist?("invoice.zip")).to be false
      end
    end
  end
end
