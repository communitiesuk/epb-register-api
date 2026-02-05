describe "Acceptance::Assessment::Lodge", :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  before do
    Events::Broadcaster.enable!
    add_countries
    add_assessor scheme_id:, assessor_id: "SPEC000000", body: valid_assessor_request_body
  end

  let(:scheme_id) { add_scheme_and_get_id }
  let(:valid_rdsap_xml) { Samples.xml "RdSAP-Schema-S-19.0" }
  let(:valid_rdsap_not_scottish_xml) { Samples.xml "RdSAP-Schema-19.0" }
  let(:valid_sap_xml) { Samples.xml "SAP-Schema-S-19.0.0" }
  let(:valid_cepc_xml) { Samples.xml "CEPC-S-7.1", "cepc" }
  let(:valid_action_plan_xml) { Samples.xml "CS63-S-7.0", "cs63" }
  let(:valid_dec_xml) { Samples.xml "DECAR-S-7.0", "dec" }
  let(:valid_dec_ar_xml) { Samples.xml "DECAR-S-7.0", "dec-ar" }
  let(:valid_dec_and_ar_xml) { Samples.xml "DECAR-S-7.0", "dec+ar" }
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

  context "when the client has a migrate Scotland role" do
    context "when migrating a Scottish domestic assessment" do
      let(:migrated_scotland_rdsap_data) do
        ActiveRecord::Base.connection.exec_query(
          "SELECT * FROM scotland.assessments WHERE assessment_id = '0000-0000-0000-0000-0000'",
        ).entries.first
      end

      context "when the xml is valid with the correct Scottish schema" do
        it "successfully migrates the assessment" do
          expect(lodge_assessment(
            assessment_body: valid_rdsap_xml,
            accepted_responses: [201],
            scopes: %w[migrate:scotland],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            schema_name: "RdSAP-Schema-S-19.0",
            migrated: true,
          ).status).to eq(201)
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

          it "successfully migrates the assessment" do
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
            expect(migrated_scotland_rdsap_data["scheme_assessor_id"]).to eq "UNQU000000"
          end
        end
      end

      context "when migrating a valid Scottish SAP assessment" do
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
        }

        it "successfully migrates the assessment" do
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

      it "rejects a migration with an incorrect schema name" do
        expect(lodge_assessment(
          assessment_body: valid_rdsap_xml,
          accepted_responses: [403],
          scopes: %w[migrate:scotland],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-19.0",
          migrated: true,
        ).status).to eq(403)
      end
    end

    context "when migrating a valid Scottish CEPC assessment" do
      expected_cepc_assessment_data = {
        "assessment_id" => "0000-0000-0000-0000-0000",
        "date_of_assessment" => "2023-07-11",
        "date_registered" => "2023-08-04",
        "type_of_assessment" => "CEPC",
        "current_energy_efficiency_rating" => 120,
        "postcode" => "FK1 1XE",
        "date_of_expiry" => "2033-08-03",
        "address_line1" => "Non-dom Property",
        "address_line2" => "Some Street",
        "address_line3" => "Bigger Line",
        "address_line4" => nil,
        "town" => "Town",
        "scheme_assessor_id" => "SPEC000000",
        "opt_out" => false,
        "address_id" => "LPRN-0000000001",
        "migrated" => true,
        "cancelled_at" => nil,
        "not_for_issue_at" => nil,
        "created_at" => "2021-06-21",
        "hashed_assessment_id" => "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a",
      }

      it "successfully migrates the assessment" do
        response = lodge_assessment assessment_body: valid_cepc_xml,
                                    accepted_responses: [201],
                                    scopes: %w[migrate:scotland],
                                    auth_data: {
                                      scheme_ids: [scheme_id],
                                    },
                                    schema_name: "CEPC-S-7.1",
                                    migrated: "true"

        cepc_data = ActiveRecord::Base.connection.exec_query(
          "SELECT * FROM scotland.assessments WHERE assessment_id = '0000-0000-0000-0000-0000'",
        ).entries.first

        expect(JSON.parse(response.body, symbolize_names: true)[:data][:assessments].first).to eq "0000-0000-0000-0000-0000"
        expect(cepc_data).to eq expected_cepc_assessment_data
      end
    end

    context "when migrating a valid Scottish Action Plan assessment" do
      expected_action_plan_assessment_data = {
        "assessment_id" => "0000-0000-0000-0000-0000",
        "date_of_assessment" => "2025-06-04",
        "date_registered" => "2025-06-11",
        "type_of_assessment" => "CS63",
        "current_energy_efficiency_rating" => 0,
        "postcode" => "FK1 1XE",
        "date_of_expiry" => "2028-12-11",
        "address_line1" => "Non-dom Property",
        "address_line2" => "",
        "address_line3" => "",
        "address_line4" => "",
        "town" => "Town",
        "scheme_assessor_id" => "SPEC000000",
        "opt_out" => false,
        "address_id" => "0000000001",
        "migrated" => true,
        "cancelled_at" => nil,
        "not_for_issue_at" => nil,
        "created_at" => "2021-06-21",
        "hashed_assessment_id" => "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a",
      }

      it "successfully migrates the assessment" do
        response = lodge_assessment assessment_body: valid_action_plan_xml,
                                    accepted_responses: [201],
                                    scopes: %w[migrate:scotland],
                                    auth_data: {
                                      scheme_ids: [scheme_id],
                                    },
                                    schema_name: "CS63-S-7.0",
                                    migrated: "true"

        action_plan_data = ActiveRecord::Base.connection.exec_query(
          "SELECT * FROM scotland.assessments WHERE assessment_id = '0000-0000-0000-0000-0000'",
        ).entries.first

        expect(JSON.parse(response.body, symbolize_names: true)[:data][:assessments].first).to eq "0000-0000-0000-0000-0000"
        expect(action_plan_data).to eq expected_action_plan_assessment_data
      end
    end

    context "when migrating a valid Scottish DEC assessment" do
      expected_dec_assessment_data = {"assessment_id" => "0000-0000-0000-0000-0000",
                                      "date_of_assessment" => "2025-04-10",
                                      "date_registered" => "2025-04-10",
                                      "type_of_assessment" => "DEC",
                                      "current_energy_efficiency_rating" => 0,
                                      "postcode" => "EH14 2SP",
                                      "date_of_expiry" => "2026-03-18",
                                      "address_line1" => "Non-dom Property",
                                      "address_line2" => "Buisness Park",
                                      "address_line3" => "",
                                      "address_line4" => "",
                                      "town" => "Town",
                                      "scheme_assessor_id" => "SPEC000000",
                                      "opt_out" => false,
                                      "address_id" => "0000000001",
                                      "migrated" => true,
                                      "cancelled_at" => nil,
                                      "not_for_issue_at" => nil,
                                      "created_at" => "2021-06-21",
                                      "hashed_assessment_id" => "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a"}

      it "successfully migrates the assessment" do
        response = lodge_assessment assessment_body: valid_dec_xml,
                                    accepted_responses: [201],
                                    scopes: %w[migrate:scotland],
                                    auth_data: {
                                      scheme_ids: [scheme_id],
                                    },
                                    schema_name: "DECAR-S-7.0",
                                    migrated: "true"

        dec_data = ActiveRecord::Base.connection.exec_query(
          "SELECT * FROM scotland.assessments WHERE assessment_id = '0000-0000-0000-0000-0000'",
          ).entries.first

        expect(JSON.parse(response.body, symbolize_names: true)[:data][:assessments].first).to eq "0000-0000-0000-0000-0000"
        expect(dec_data).to eq expected_dec_assessment_data
      end
    end

    context "when migrating a valid Scottish DEC-AR assessment" do
      expected_dec_ar_assessment_data = {"assessment_id" => "0000-0000-0000-0000-0000",
                                      "date_of_assessment" => "2019-10-21",
                                      "date_registered" => "2019-11-22",
                                      "type_of_assessment" => "DEC-AR",
                                      "current_energy_efficiency_rating" => 0,
                                      "postcode" => "EH14 2SP",
                                      "date_of_expiry" => "2029-11-21",
                                      "address_line1" => "Non-dom Property",
                                      "address_line2" => "Buisness Park",
                                      "address_line3" => "",
                                      "address_line4" => "",
                                      "town" => "Town",
                                      "scheme_assessor_id" => "SPEC000000",
                                      "opt_out" => false,
                                      "address_id" => "0000000001",
                                      "migrated" => true,
                                      "cancelled_at" => nil,
                                      "not_for_issue_at" => nil,
                                      "created_at" => "2021-06-21",
                                      "hashed_assessment_id" => "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a"}

      it "successfully migrates the assessment" do
        response = lodge_assessment assessment_body: valid_dec_ar_xml,
                                    accepted_responses: [201],
                                    scopes: %w[migrate:scotland],
                                    auth_data: {
                                      scheme_ids: [scheme_id],
                                    },
                                    schema_name: "DECAR-S-7.0",
                                    migrated: "true"

        dec_ar_data = ActiveRecord::Base.connection.exec_query(
          "SELECT * FROM scotland.assessments WHERE assessment_id = '0000-0000-0000-0000-0000'",
          ).entries.first

        expect(JSON.parse(response.body, symbolize_names: true)[:data][:assessments].first).to eq "0000-0000-0000-0000-0000"
        expect(dec_ar_data).to eq expected_dec_ar_assessment_data
      end
    end

    context "when migrating a valid Scottish DEC+AR assessment" do
      expected_dec_assessment_data = {"assessment_id" => "0000-0000-0000-0000-0000",
                                      "date_of_assessment" => "2025-04-02",
                                      "date_registered" => "2025-06-18",
                                      "type_of_assessment" => "DEC",
                                      "current_energy_efficiency_rating" => 0,
                                      "postcode" => "EH14 2SP",
                                      "date_of_expiry" => "2035-03-31",
                                      "address_line1" => "Non-dom Property",
                                      "address_line2" => "Buisness Park",
                                      "address_line3" => "",
                                      "address_line4" => "",
                                      "town" => "Town",
                                      "scheme_assessor_id" => "SPEC000000",
                                      "opt_out" => false,
                                      "address_id" => "0000000001",
                                      "migrated" => true,
                                      "cancelled_at" => nil,
                                      "not_for_issue_at" => nil,
                                      "created_at" => "2021-06-21",
                                      "hashed_assessment_id" => "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a"}
      expected_dec_ar_assessment_data = {"assessment_id" => "0000-0000-0000-0000-0001",
                                         "date_of_assessment" => "2025-04-02",
                                         "date_registered" => "2025-06-18",
                                         "type_of_assessment" => "DEC-AR",
                                         "current_energy_efficiency_rating" => 0,
                                         "postcode" => "EH14 2SP",
                                         "date_of_expiry" => "2035-06-17",
                                         "address_line1" => "Non-dom Property",
                                         "address_line2" => "Buisness Park",
                                         "address_line3" => "",
                                         "address_line4" => "",
                                         "town" => "Town",
                                         "scheme_assessor_id" => "SPEC000000",
                                         "opt_out" => false,
                                         "address_id" => "0000000001",
                                         "migrated" => true,
                                         "cancelled_at" => nil,
                                         "not_for_issue_at" => nil,
                                         "created_at" => "2021-06-21",
                                         "hashed_assessment_id" => "55ce7d026c13e923d26cbfb0d6ed60734d3270ba981d629a168bb8eb2da3f8c4"}
      expected_linked_assessment_data = [{"assessment_id" => "0000-0000-0000-0000-0000", "linked_assessment_id" => "0000-0000-0000-0000-0001"}]

      it "successfully migrates the assessment" do
        response = lodge_assessment assessment_body: valid_dec_and_ar_xml,
                                    accepted_responses: [201],
                                    scopes: %w[migrate:scotland],
                                    auth_data: {
                                      scheme_ids: [scheme_id],
                                    },
                                    schema_name: "DECAR-S-7.0",
                                    migrated: "true"

        dec_data = ActiveRecord::Base.connection.exec_query(
          "SELECT * FROM scotland.assessments WHERE assessment_id = '0000-0000-0000-0000-0000'",
          ).entries.first

        dec_ar_data = ActiveRecord::Base.connection.exec_query(
          "SELECT * FROM scotland.assessments WHERE assessment_id = '0000-0000-0000-0000-0001'",
          ).entries.first

        linked_assessments = ActiveRecord::Base.connection.exec_query(
          "SELECT * FROM scotland.linked_assessments WHERE assessment_id = '0000-0000-0000-0000-0000'",
          ).entries

        expect(JSON.parse(response.body, symbolize_names: true)[:data][:assessments].first).to eq "0000-0000-0000-0000-0000"
        expect(dec_ar_data).to eq expected_dec_ar_assessment_data
        expect(dec_data).to eq expected_dec_assessment_data
        expect(linked_assessments).to eq expected_linked_assessment_data
      end
    end

    context "when migrating a non-Scottish domestic assessment" do
      it "rejects a migration" do
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

      it "rejects a migration when the schema name incorrectly indicates it is Scottish" do
        expect(lodge_assessment(
          assessment_body: valid_rdsap_not_scottish_xml,
          accepted_responses: [400],
          scopes: %w[migrate:scotland],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-S-19.0",
          migrated: true,
        ).status).to eq(400)
      end
    end

    context "when attempting to lodge a Scottish domestic assessment" do
      it "rejects the Scottish assessment" do
        expect(lodge_assessment(
          assessment_body: valid_rdsap_xml,
          accepted_responses: [403],
          scopes: %w[migrate:scotland assessment:lodge],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-S-19.0",
          migrated: false,
        ).status).to eq(403)
      end

      it "rejects the non-Scottish assessment" do
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
    end
  end

  context "when the client does not have a migrate:scotland role" do
    context "when the client has a migrate assessment role" do
      it "rejects a migration of a Scottish domestic assessment" do
        expect(lodge_assessment(
          assessment_body: valid_rdsap_xml,
          accepted_responses: [403],
          scopes: %w[migrate:assessment],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "RdSAP-Schema-S-19.0",
          migrated: true,
        ).status).to eq(403)
      end
    end

    context "when the client has a lodgement role" do
      it "rejects a migration from a client with a lodgement role" do
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
    end
  end
end
