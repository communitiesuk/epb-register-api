describe "UseCase::CertificateSummary", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    Timecop.freeze(2021, 2, 22, 0, 0, 0)
  end

  after(:all) do
    Timecop.return
  end

  context "when extracting a certificate summary data for a single certificate" do
    subject(:use_case) { UseCase::CertificateSummary::Fetch.new(certificate_summary_gateway:, green_deal_plans_gateway:, related_assessments_gateway:) }

    let(:certificate_summary_gateway) do
      instance_double(Gateway::CertificateSummaryGateway)
    end

    let(:green_deal_plans_gateway) do
      instance_double(Gateway::GreenDealPlansGateway)
    end

    let(:related_assessments_gateway) do
      instance_double(Gateway::RelatedAssessmentsGateway)
    end

    let(:xml_data) do
      {
        "created_at" => "2021-02-22 00:00:00 UTC",
        "opt_out" => false,
        "cancelled_at" => nil,
        "not_for_issue_at" => nil,
        "assessment_address_id" => "UPRN-000000000000",
        "country_id" => 3,
        "scheme_assessor_id" => "SPEC000000",
        "assessor_first_name" => "Someone",
        "assessor_last_name" => "Person",
        "assessor_telephone_number" => "010199991010101",
        "assessor_email" => "person@person.com",
        "scheme_id" => 1,
        "scheme_name" => "test scheme",
        "schema_type" => "RdSAP-Schema-20.0.0",
        "xml" => xml_fixture,
        "green_deal_plan_id" => nil,
        "count_address_id_assessments" => 1,
      }
    end

    let(:xml_data_related_assessments) do
      {
        "created_at" => "2021-02-22 00:00:00 UTC",
        "opt_out" => false,
        "cancelled_at" => nil,
        "not_for_issue_at" => nil,
        "assessment_address_id" => "UPRN-000000000001",
        "country_id" => 3,
        "scheme_assessor_id" => "SPEC000000",
        "assessor_first_name" => "Someone",
        "assessor_last_name" => "Person",
        "assessor_telephone_number" => "010199991010101",
        "assessor_email" => "person@person.com",
        "scheme_id" => 1,
        "scheme_name" => "test scheme",
        "schema_type" => "RdSAP-Schema-20.0.0",
        "xml" => xml_fixture,
        "green_deal_plan_id" => nil,
        "count_address_id_assessments" => 2,
      }
    end

    let(:xml_fixture) do
      Samples.xml "RdSAP-Schema-20.0.0"
    end

    let(:green_deal_data) do
      [
        {
          "greenDealPlanId": "AC0000000005",
          "startDate": "2012-01-19",
          "endDate": "2032-01-13",
          "providerDetails": {
            "name": "HOME ENERGY AND LIFESTYLE MANAGEMENT",
            "telephone": "01010100000",
            "email": "admin@office.co.uk",
          },
          "interest": {
            "rate": "8.07",
            "fixed": true,
          },
          "chargeUplift": {
            "amount": "0.0",
            "date": nil,
          },
          "ccaRegulated": true,
          "structureChanged": false,
          "measuresRemoved": false,
          "measures": [
            {
              "product": "Solar photovoltaic panels",
              "repaidDate": "2032-01-15 00:00:00.000000",
            },
          ],
          "charges": [
            {
              "endDate": "2032-01-12 00:00:00.000000",
              "startDate": "2012-01-16 00:00:00.000000",
              "dailyCharge": 1.01,
            },
            {
              "endDate": "2032-01-13 00:00:00.000000",
              "startDate": "2032-01-13 00:00:00.000000",
              "dailyCharge": 0.8,
            },
          ],
          "savings": [
            {
              "fuelCode": "39",
              "fuelSaving": 2572,
              "standingChargeFraction": 0,
            },
          ],
          "estimatedSavings": 622,
        },
      ]
    end

    let(:related_assessments_data) do
    end

    let(:scheme_id) do
      add_scheme_and_get_id
    end

    before do
      add_super_assessor(scheme_id:)
      allow(certificate_summary_gateway).to receive(:fetch).and_return(xml_data)
      allow(green_deal_plans_gateway).to receive(:fetch).and_return(green_deal_data)
      allow(related_assessments_gateway).to receive(:by_address_id)
    end

    it "can load the class as expected" do
      expect { use_case }.not_to raise_error
    end

    it "does not raise and error" do
      expect { use_case.execute("0000-0000-0000-0000-0000") }.not_to raise_error
    end

    it "can execute and return the expected hash" do
      results = use_case.execute("0000-0000-0000-0000-0000")
      expect(results).to eq(xml_data)
    end

    it "does not call the green deal plan gateway when there is not a green deal plan" do
      use_case.execute("0000-0000-0000-0000-0000")
      expect(green_deal_plans_gateway).not_to have_received(:fetch)
    end

    it "can execute and return the expected hash with green deal when there is a green deal plan" do
      xml_data["green_deal_plan_id"] = "AC0000000005"
      results = use_case.execute("0000-0000-0000-0000-0000")
      expect(results["green_deal_plan"]).to eq(green_deal_data)
    end

    it "does not call the related assessments gateway when there are no related assessments" do
      use_case.execute("0000-0000-0000-0000-0000")
      expect(related_assessments_gateway).not_to have_received(:by_address_id)
    end

    it "does call the related assessments gateway when there are related assessments" do
      allow(certificate_summary_gateway).to receive(:fetch).and_return(xml_data_related_assessments)
      use_case.execute("0000-0000-0000-0000-0000")
      expect(related_assessments_gateway).to have_received(:by_address_id)
    end
  end
end
