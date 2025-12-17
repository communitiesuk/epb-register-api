describe "Acceptance::Assessment::Lodge", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  before do
    Events::Broadcaster.enable!
    add_countries
  end

  let(:valid_rdsap_xml) { Samples.xml "RdSAP-Schema-S-19.0" }
  let(:valid_rdsap_not_scottish_xml) { Samples.xml "RdSAP-Schema-19.0" }
  let(:valid_sap_xml) { Samples.xml "SAP-Schema-S-19.0.0" }
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

  context "when migrating a domestic Scottish assessment" do
    let(:scheme_id) { add_scheme_and_get_id }

    let(:migrated_scotland_rdsap_data) do
      ActiveRecord::Base.connection.exec_query(
        "SELECT * FROM scotland.assessments WHERE assessment_id = '0000-0000-0000-0000-0000'",
      ).entries.first
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

    it "rejects a migration from a client with a Scottish migration role but without a Scottish schema" do
      expect(lodge_assessment(
        assessment_body: valid_rdsap_not_scottish_xml,
        accepted_responses: [403],
        scopes: %w[migrate:scotland],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-19.0",
        migrated: true,
      ).status).to eq(403)
    end

    it "rejects a lodgement from a client with a Scottish migration role but without a Scottish schema" do
      expect(lodge_assessment(
        assessment_body: valid_rdsap_not_scottish_xml,
        accepted_responses: [403],
        scopes: %w[migrate:scotland],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-19.0",
        migrated: false,
      ).status).to eq(403)
    end

    it "rejects a lodgement from a client with a Scottish migration role" do
      expect(lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [403],
        scopes: %w[migrate:scotland],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "RdSAP-Schema-S-19.0",
        migrated: false,
      ).status).to eq(403)
    end

    it "has all expected data points present" do
      expected_rdsap_data = {
        "assessment_id" => "0000-0000-0000-0000-0000",
        "date_of_assessment" => "2023-06-27",
        "date_registered" => "2023-06-27",
        "type_of_assessment" => "RdSAP",
        "current_energy_efficiency_rating" => 79,
        "postcode" => "FK1 1XE",
        "date_of_expiry" => "2033-06-26",
        "address_line1" => "1 Some Street",
        "address_line2" => "",
        "address_line3" => "",
        "address_line4" => "",
        "town" => "Newkirk",
        "scheme_assessor_id" => "SPEC000000",
        "opt_out" => false,
        "address_id" => "LPRN-0000000000",
        "migrated" => true,
        "cancelled_at" => nil,
        "not_for_issue_at" => nil,
        "created_at" => "2021-06-21",
        "hashed_assessment_id" => "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a",
        "test_column" => nil,
      }

      response = lodge_assessment assessment_body: valid_rdsap_xml,
                                  accepted_responses: [201],
                                  scopes: %w[migrate:scotland],
                                  auth_data: {
                                    scheme_ids: [scheme_id],
                                  },
                                  schema_name: "RdSAP-Schema-S-19.0",
                                  migrated: "true"

      expect(JSON.parse(response.body, symbolize_names: true)[:data][:assessments].first).to eq "0000-0000-0000-0000-0000"
      expect(migrated_scotland_rdsap_data).to eq expected_rdsap_data
    end

    context "when migrating the same assessment ID" do
      before do
        lodge_assessment assessment_body: valid_rdsap_xml,
                         accepted_responses: [201],
                         scopes: %w[migrate:scotland],
                         auth_data: {
                           scheme_ids: [scheme_id],
                         },
                         schema_name: "RdSAP-Schema-S-19.0",
                         migrated: "true"
      end

      it "doesn't raise and error" do
        lodge_assessment assessment_body: valid_rdsap_xml,
                         accepted_responses: [201],
                         scopes: %w[migrate:scotland],
                         auth_data: {
                           scheme_ids: [scheme_id],
                         },
                         schema_name: "RdSAP-Schema-S-19.0",
                         migrated: "true"
        expect { migrated_scotland_rdsap_data["migrated"] }.not_to raise_error
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
                                    scopes: %w[migrate:scotland],
                                    auth_data: {
                                      scheme_ids: [scheme_id],
                                    },
                                    schema_name: "RdSAP-Schema-S-19.0",
                                    migrated: true).status

        expect(response).to eq 201
        expect(migrated_scotland_rdsap_data["migrated"]).to be_truthy
      end
    end

    context "when migrating a Scottish SAP assessment" do
      expected_sap_assessment_data = {
        "assessment_id" => "0000-0000-0000-0000-0000",
        "date_of_assessment" => "2024-11-21",
        "date_registered" => "2024-11-21",
        "type_of_assessment" => "SAP",
        "current_energy_efficiency_rating" => 91,
        "postcode" => "EH1 2NG",
        "date_of_expiry" => "2034-11-20",
        "address_line1" => "1 LOVELY ROAD",
        "address_line2" => "NICE ESTATE",
        "address_line3" => "",
        "address_line4" => nil,
        "town" => "TOWN",
        "scheme_assessor_id" => "SPEC000000",
        "opt_out" => false,
        "address_id" => "0000000001",
        "migrated" => true,
        "cancelled_at" => nil,
        "not_for_issue_at" => nil,
        "created_at" => "2021-06-21",
        "hashed_assessment_id" => "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a",
        "test_column" => nil,
      }

      it "is true in migrated column" do
        response = lodge_assessment assessment_body: valid_sap_xml,
                                    accepted_responses: [201],
                                    scopes: %w[migrate:scotland],
                                    auth_data: {
                                      scheme_ids: [scheme_id],
                                    },
                                    schema_name: "SAP-Schema-S-19.0.0",
                                    migrated: "true"

        sap_data =  ActiveRecord::Base.connection.exec_query(
          "SELECT * FROM scotland.assessments WHERE assessment_id = '0000-0000-0000-0000-0000'",
        ).entries.first

        expect(JSON.parse(response.body, symbolize_names: true)[:data][:assessments].first).to eq "0000-0000-0000-0000-0000"
        expect(sap_data).to eq expected_sap_assessment_data
      end
    end
  end
end
