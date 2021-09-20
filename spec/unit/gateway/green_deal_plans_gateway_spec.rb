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
        VALUES ('0000-0000-0000-0000-0000', 'TEST123456', '2070-01-05')",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO green_deal_plans (green_deal_plan_id)
        VALUES ('ABC123456DEF')",
      )
      ActiveRecord::Base.connection.exec_query(
        "INSERT INTO green_deal_assessments (green_deal_plan_id, assessment_id)
        VALUES ('ABC123456DEF', '0000-0000-0000-0000-0000')",
      )
    end

    it "returns the assessment id for the green deal plan" do
      expect(gateway.fetch_assessment_id(plan_id: "ABC123456DEF")).to eq("0000-0000-0000-0000-0000")
    end
  end
end
