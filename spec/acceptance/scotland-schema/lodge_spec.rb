describe "Acceptance::Assessment::Lodge", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  before do
    add_countries
  end

  let(:valid_rdsap_xml) { Samples.xml "RdSAP-Schema-S-19.0" }
  let(:scheme_id) { add_scheme_and_get_id }
  let(:valid_assessor_request_body) do
    AssessorStub.new.fetch_request_body(
      domestic_rd_sap: "ACTIVE",
      domestic_sap: "ACTIVE",
      non_domestic_nos3: "ACTIVE",
      non_domestic_dec: "ACTIVE",
      non_domestic_cc4: "ACTIVE",
      non_domestic_sp3: "ACTIVE",
    )
  end
  let(:expected_lodgement) do
    {}
  end

  context "when migrating a Scottish assessment" do
    let(:scheme_id) { add_scheme_and_get_id }

    let(:migrated_column_scotland) do
      ActiveRecord::Base.connection.exec_query(
        "SELECT migrated FROM scotland.assessments WHERE assessment_id = '0000-0000-0000-0000-0000'",
      )
    end

    before do
      add_assessor scheme_id:, assessor_id: "SPEC000000", body: valid_assessor_request_body
    end

    it "rejects a migration from a client without migration role" do
      expect(lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [403],
        scopes: %w[assessment:lodge],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-S-19.0",
        migrated: true,
      ).status).to eq(403)
    end

    it "is true in migrated column" do
      response = lodge_assessment assessment_body: valid_rdsap_xml,
                                  accepted_responses: [201],
                                  scopes: %w[assessment:lodge migrate:assessment],
                                  auth_data: {
                                    scheme_ids: [scheme_id],
                                  },
                                  schema_name: "RdSAP-Schema-S-19.0",
                                  migrated: "true"

      expect(JSON.parse(response.body, symbolize_names: true)[:data][:assessments].first).to eq "0000-0000-0000-0000-0000"
      expect(migrated_column_scotland.entries.first["migrated"]).to be_truthy
    end

    context "when migrating the same assessment ID" do
      before do
        lodge_assessment assessment_body: valid_rdsap_xml,
                         accepted_responses: [201],
                         scopes: %w[assessment:lodge migrate:assessment],
                         auth_data: {
                           scheme_ids: [scheme_id],
                         },
                         schema_name: "RdSAP-Schema-S-19.0",
                         migrated: "true"
      end

      it "is true in migrated column" do
        lodge_assessment assessment_body: valid_rdsap_xml,
                         accepted_responses: [201],
                         scopes: %w[assessment:lodge migrate:assessment],
                         auth_data: {
                           scheme_ids: [scheme_id],
                         },
                         schema_name: "RdSAP-Schema-S-19.0",
                         migrated: "true"
        expect(migrated_column_scotland.entries.first["migrated"]).to be_truthy
      end
    end

    context "when migrating an assessment submitted by an assessor who is now unqualified" do
      let(:rdsap_xml) do
        add_assessor scheme_id:,
                     assessor_id: "UNQU000000",
                     body: AssessorStub.new.fetch_request_body(
                       domestic_rd_sap: "INACTIVE",
                     )

        xml = Nokogiri.XML valid_rdsap_xml

        xml.css("Membership-Number").children.first.content = "UNQU000000"

        xml.to_s
      end

      it "is true in migrated column" do
        response = lodge_assessment(assessment_body: rdsap_xml,
                                    accepted_responses: [201],
                                    scopes: %w[assessment:lodge migrate:assessment],
                                    auth_data: {
                                      scheme_ids: [scheme_id],
                                    },
                                    schema_name: "RdSAP-Schema-S-19.0",
                                    migrated: true).status

        expect(response).to eq 201
        expect(migrated_column_scotland.entries.first["migrated"]).to be_truthy
      end
    end
  end
end
