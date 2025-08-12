require "rspec"

describe "create_function_for_new_schema and create_new_schema" do
  include RSpecRegisterApiServiceMixin
  let(:create_function_for_new_schema) { get_task("db:create_function_for_new_schema") }
  let(:create_new_schema) { get_task("db:create_new_schema") }

  context "when invoking create_function_for_new_schema" do
    it "does not raise an error" do
      expect { create_function_for_new_schema.invoke }.not_to raise_error
    end
  end

  context "when invoking create_new_schema" do
    # it "raises a missing argument error" do
    #   expect { create_new_schema.invoke }.to raise_error(Boundary::ArgumentMissing)
    # end
    #
    # it "raise an error unless create_function_for_new_schema have been invoked first" do
    #   expect { create_new_schema.invoke("public", "scotland", true) }.to raise_error(ActiveRecord::StatementInvalid)
    # end
    #
    # it "does not raise error if create_function_for_new_schema has been invoked first" do
    #   create_function_for_new_schema.invoke
    #   expect { create_new_schema.invoke("public", "scotland", true) }.not_to raise_error
    # end

    it "creates a new scotland schema" do
      create_function_for_new_schema.invoke
      create_new_schema.invoke("public", "scotland", true)
      current_schema = ActiveRecord::Base.connection.exec_query <<~SQL
        SELECT schema_name FROM information_schema.schemata
      SQL

      is_scotland_present = current_schema.rows.flatten.include?("scotland")

      expect(is_scotland_present).to be(true)
    end

    it "creates the required new scotland tables" do
      create_function_for_new_schema.invoke
      create_new_schema.invoke("public", "scotland", true)
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
        SELECT table_name FROM information_schema.tables WHERE table_schema = 'scotland';
      SQL
      tables = table_results.rows.flatten
      pp tables
      expect(tables).to eq(expected_tables)
    end
  end
end
