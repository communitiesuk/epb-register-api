describe "monthly invoice export" do
  let(:monthly_invoice_rake) { get_task("data_export:export_invoices") }

  context "when two arguments are passed to the rake" do
    let(:use_case) { instance_double(UseCase::GetAssessmentCountBySchemeNameAndType) }
    let(:returned_data) { [{ type_of_assessment: "AC-CERT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 2 }, { type_of_assessment: "AC-REPORT", scheme_name: "Elmhurst Energy Systems Ltd", number_of_assessments: 3 }] }

    before do
      allow(ApiFactory).to receive(:get_assessment_count_by_scheme_name_type).and_return(use_case)
      allow(use_case).to receive(:execute).and_return []
    end

    context "when there is no data" do
      it "raises a no data error" do
        expect { monthly_invoice_rake.invoke("22-08-01", "22-08-31") }.to raise_error Boundary::NoData, "no data to be saved for: get assessment count by scheme name and type"
      end
    end

    context "when there is data" do
      let(:File) { class_double(File) }

      before do
        allow(use_case).to receive(:execute).and_return returned_data
        WebMock.enable!
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("STAGE").and_return("TEST")
        allow(ENV).to receive(:[]).with("SLACK_SUPPORT_URL").and_return("https://example.com/webhook")
        allow(File).to receive(:write)
        allow(File).to receive(:open)
        allow(File).to receive(:delete)
        WebMock.stub_request(:post, "https://example.com/webhook").to_return(status: 200, headers: {})
      end

      it "calls the expected use case" do
        monthly_invoice_rake.invoke("22-08-01", "22-08-31")
        expect(use_case).to have_received(:execute).with(Date.parse("22-08-01"), Date.parse("22-08-31")).exactly(1).times
      end

      it "does not raise and error" do
        expect { monthly_invoice_rake.invoke("22-08-01", "22-08-31") }.not_to raise_error
      end

      it "writes a csv to the disk" do
        monthly_invoice_rake.invoke("22-08-01", "22-08-31")
        expect(File).to have_received(:write).with("assessment_count_by_scheme_name_type.csv", "type_of_assessment,scheme_name,number_of_assessments\nAC-CERT,Elmhurst Energy Systems Ltd,2\nAC-REPORT,Elmhurst Energy Systems Ltd,3\n")
      end

      it "posts the csv to slack" do
        monthly_invoice_rake.invoke("22-08-01", "22-08-31")
        expect(File).to have_received(:open).with("assessment_count_by_scheme_name_type.csv")
        expect(WebMock).to have_requested(
          :post,
          "https://example.com/webhook",
        ).with(headers: { "Content-Type" => %r{multipart/form-data} })
      end

      it "deletes the file" do
        monthly_invoice_rake.invoke("22-08-01", "22-08-31")
        expect(File).to have_received(:delete).with("assessment_count_by_scheme_name_type.csv")
      end
    end
  end
end
