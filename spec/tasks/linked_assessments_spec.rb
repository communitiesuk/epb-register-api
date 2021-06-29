require "rspec"

describe "LinkedAssessments" do
  include RSpecRegisterApiServiceMixin

  before(:all) do
    scheme_id = add_scheme_and_get_id
    add_super_assessor(scheme_id)

    cepc_schema = "CEPC-8.0.0".freeze

    cepc_xml = Nokogiri.XML Samples.xml(cepc_schema, "cepc+rr")
    call_lodge_assessment(scheme_id: scheme_id, schema_name: cepc_schema, xml_document: cepc_xml)
  end

  context "When the task runs without any address ID mismatch" do
    before { allow(STDOUT).to receive(:puts) }

    it "does not find any linked assessment to change" do
      expect { get_task("linked_assessments_address_id").invoke }.to output(
        /skipped:1 changed:0/,
      ).to_stdout
    end
  end

  context "When the task runs with an address ID mismatch" do
    before do
      allow(STDOUT).to receive(:puts)
      update_rr_address_id = <<-SQL
         UPDATE assessments_address_id
         SET address_id = 'RRN-0000-0000-0000-0000-0001'
         WHERE assessment_id = '0000-0000-0000-0000-0001'
      SQL
      ActiveRecord::Base.connection.exec_query(update_rr_address_id)
    end

    it "does find a linked assessment to change" do
      expect { get_task("linked_assessments_address_id").invoke }.to output(
        /skipped:0 changed:1/,
      ).to_stdout
    end

    it "preserves the certificate address ID" do
      get_task("linked_assessments_address_id").invoke

      assessment =
        JSON.parse(
          fetch_assessment_summary("0000-0000-0000-0000-0000").body,
          symbolize_names: true,
        )
      expect(assessment[:data][:addressId]).to eq(
        "UPRN-000000000001",
      )
    end

    it "changes the recommendation report address ID" do
      get_task("linked_assessments_address_id").invoke

      rr_assessment =
        JSON.parse(
          fetch_assessment_summary("0000-0000-0000-0000-0001").body,
          symbolize_names: true,
        )
      expect(rr_assessment[:data][:addressId]).to eq(
        "UPRN-000000000001",
      )
    end
  end

  context "When the task runs with an address ID mismatch done by EPBR support" do
    before do
      allow(STDOUT).to receive(:puts)
      update_rr_address_id = <<-SQL
         UPDATE assessments_address_id
         SET address_id = 'RRN-0000-0000-0000-0000-0001', source = 'epb_team_update'
         WHERE assessment_id = '0000-0000-0000-0000-0001'
      SQL
      ActiveRecord::Base.connection.exec_query(update_rr_address_id)
    end

    it "does not find any linked assessment to change" do
      expect { get_task("linked_assessments_address_id").invoke }.to output(
        /skipped:1 changed:0/,
      ).to_stdout
    end

    it "preserves the modified recommendation report address ID" do
      get_task("linked_assessments_address_id").invoke

      assessment =
        JSON.parse(
          fetch_assessment_summary("0000-0000-0000-0000-0001").body,
          symbolize_names: true,
        )
      expect(assessment[:data][:addressId]).to eq(
        "RRN-0000-0000-0000-0000-0001",
      )
    end
  end
end
