require "notifications/client"

describe "monthly invoice export" do
  let(:monthly_invoice_rake) { get_task("data_export:export_invoices") }

  context "when invalid date range is passed " do
    it "raises a no data error" do
      expect { monthly_invoice_rake.invoke("22-08-01", "21-08-31", "schema_name_type") }.to raise_error Boundary::NoData, "no data to be saved for: get assessment count by scheme name and type"
    end
  end

  context "when two arguments are passed to the rake" do
    let(:notify_client) { instance_double(Notifications::Client) }

    before do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with("NOTIFY_API_KEY").and_return("123456")
      allow(ENV).to receive(:[]).with("INVOICE_EMAIL_RECIPIENT").and_return("test@test.com")
      allow(ENV).to receive(:[]).with("INVOICE_TEMPLATE_ID").and_return("f33517ff-2a88-4f6e-b855-c550268ce08a")
      allow(ApiFactory).to receive(:notify_client).and_return(notify_client)
      allow(notify_client).to receive(:send_email).and_return(nil)
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
        monthly_invoice_rake.invoke("22-08-01", "22-08-31", "schema_name_type")
        expect(use_case).to have_received(:execute).with(Date.parse("22-08-01"), Date.parse("22-08-31")).exactly(1).times
      end

      it "does not raise and error" do
        expect { monthly_invoice_rake.invoke("22-08-01", "22-08-31", "schema_name_type") }.not_to raise_error
      end

      it "emails the generated file via notify" do
        monthly_invoice_rake.invoke("22-08-01", "22-08-31", "schema_name_type")
        expect(notify_client).to have_received(:send_email).with(email_address: "test@test.com",
                                                                 template_id: "f33517ff-2a88-4f6e-b855-c550268ce08a",
                                                                 personalisation:
                                                                    { report_type: "schema_name_type",
                                                                      link_to_file:
                                                                           { file:
                                                                                   "dHlwZV9vZl9hc3Nlc3NtZW50LHNjaGVtZV9uYW1lLG51bWJlcl9vZl9hc3Nlc3NtZW50cwpBQy1DRVJULEVsbWh1cnN0IEVuZXJneSBTeXN0ZW1zIEx0ZCwyCkFDLVJFUE9SVCxFbG1odXJzdCBFbmVyZ3kgU3lzdGVtcyBMdGQsMwo=",
                                                                             is_csv: true } }).exactly(1).times
      end

      it "generated file does not exist" do
        expect(File.exist?("assessment_count_by_scheme_name_type.csv")).to be false
      end
    end

    context "when there is invoice data for get assessment count by region and type" do
      let(:use_case) { instance_double(UseCase::GetAssessmentCountByRegionAndType) }
      let(:returned_data) { [{ number_of_assessments: 122, type_of_assessment: "AC-CERT", region: "Eastern" }, { number_of_assessments: 153, type_of_assessment: "CEPC", region: "Northern Ireland " }] }

      before do
        allow(ApiFactory).to receive(:get_assessment_count_by_region_type).and_return(use_case)
        allow(use_case).to receive(:execute).and_return returned_data
      end

      it "calls the expected use case" do
        monthly_invoice_rake.invoke("22-08-01", "22-08-31", "region_type")
        expect(use_case).to have_received(:execute).with(Date.parse("22-08-01"), Date.parse("22-08-31")).exactly(1).times
      end
    end
  end
end
