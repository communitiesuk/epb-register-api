require "rspec"

describe "create_function_for_new_schema and create_new_schema" do
  include RSpecRegisterApiServiceMixin

  context "when invoking create_new_schema" do
    it "creates a new scotland schema" do

      current_schema = ActiveRecord::Base.connection.exec_query <<~SQL
        SELECT schema_name FROM information_schema.schemata
      SQL

      is_scotland_present = current_schema.rows.flatten.include?("scotland")
      pp current_schema
      expect(is_scotland_present).to be(true)
    end

    it "creates the required new scotland tables" do
      expected_tables = %w[assessment_search_address
                           assessments_address_id
                           linked_assessments
                           overridden_lodgement_events
                           schema_migrations
                           assessments
                           assessments_country_ids
                           assessments_xml
                           green_deal_assessments]
      table_results = ActiveRecord::Base.connection.exec_query <<~SQL
        -- SELECT table_schema FROM information_schema.tables
        SELECT table_name FROM information_schema.tables WHERE table_schema = 'scotland';
      SQL
      pp table_results
      tables = table_results.rows.flatten
      # pp tables
      expect(tables).to eq(expected_tables)
    end
  end
end
