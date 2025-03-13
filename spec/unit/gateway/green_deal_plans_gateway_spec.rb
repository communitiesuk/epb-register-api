describe Gateway::GreenDealPlansGateway do
  include RSpecRegisterApiServiceMixin
  subject(:gateway) { described_class.new }

  describe "#fetch_assessment_id" do
    before do
      ActiveRecord::Base.connection.exec_query("INSERT INTO schemes (scheme_id) VALUES ('9999')")
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessors (scheme_assessor_id, first_name, last_name, date_of_birth, registered_by)
        VALUES ('TEST123456', 'test_forename', 'test_surname', '1970-01-05', 9999)",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO assessments (assessment_id, scheme_assessor_id, date_of_expiry)
        VALUES ('0000-0000-0000-0000-0000', 'TEST123456', '2070-01-05'), ('0000-0000-0000-0000-0001', 'TEST123456', '2070-01-06')",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO green_deal_plans (green_deal_plan_id)
        VALUES ('ABC123456DEF')",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO green_deal_assessments (green_deal_plan_id, assessment_id)
        VALUES ('ABC123456DEF', '0000-0000-0000-0000-0000'), ('ABC123456DEF', '0000-0000-0000-0000-0001')",
      )
    end

    it "returns all the assessment IDs for the green deal plan" do
      expect(gateway.fetch_assessment_ids(plan_id: "ABC123456DEF")).to eq(%w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001])
    end
  end

  describe "#fetch" do
    let(:scheme_id) { add_scheme_and_get_id }

    before do
      add_super_assessor(scheme_id:)
      load_green_deal_data
      add_assessment_with_green_deal(
        type: "RdSAP",
        assessment_id: "0000-0000-0000-0000-1111",
        registration_date: "2024-10-10",
        green_deal_plan_id: "ABC654321DEF",
      )
      add_assessment_with_green_deal(
        type: "RdSAP",
        assessment_id: "0000-0000-0000-0000-1111",
        registration_date: "2024-10-10",
        green_deal_plan_id: "ABC654321RRR",
      )
    end

    it "returns each green deal plan for an assessment" do
      result = gateway.fetch("0000-0000-0000-0000-1111")
      expect(result.first).to be_an_instance_of Domain::GreenDealPlan
      expect(result.second).to be_an_instance_of Domain::GreenDealPlan
      expect(result.first.green_deal_plan_id).to eq "ABC654321DEF"
      expect(result.second.green_deal_plan_id).to eq "ABC654321RRR"
    end
  end
end
