# frozen_string_literal: true

describe "Acceptance::Assessment::Lodge", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  let(:valid_assessor_request_body) do
    AssessorStub.new.fetch_request_body(
      domesticRdSap: "ACTIVE",
      nonDomesticNos3: "ACTIVE",
      nonDomesticDec: "ACTIVE",
      nonDomesticCc4: "ACTIVE",
      nonDomesticSp3: "ACTIVE",
    )
  end

  let(:valid_rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }
  let(:valid_cepc_rr_xml) { Samples.xml "CEPC-8.0.0", "cepc+rr" }
  let(:valid_dec_rr_xml) { Samples.xml "CEPC-8.0.0", "dec+rr" }
  let(:valid_ac_cert_report_xml) do
    Samples.xml "CEPC-8.0.0", "ac-cert+ac-report"
  end

  context "rejecting lodgements" do
    let(:scheme_id) { add_scheme_and_get_id }
    let(:doc) { Nokogiri.XML valid_rdsap_xml }
    let(:register_assessor) do
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)
    end

    it "rejects an assessment with a schema that does not exist" do
      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [400],
        schema_name: "MakeupSAP-20.0.0",
      )
    end

    it "rejects an assessment from an unregistered assessor" do
      response =
        JSON.parse(
          lodge_assessment(
            assessment_body: valid_rdsap_xml,
            accepted_responses: [400],
            auth_data: {
              scheme_ids: [scheme_id],
            },
          ).body,
        )

      expect(response["errors"][0]["title"]).to eq(
        "Assessor is not registered.",
      )
    end

    it "rejects an assessment with an unsupported schema" do
      response =
        JSON.parse(
          lodge_assessment(
            assessment_body: valid_cepc_rr_xml,
            accepted_responses: [400],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            schema_name: "unsupported",
          ).body,
        )

      expect(response["errors"][0]["title"]).to eq("Schema is not supported.")
    end

    it "rejects an assessment with a missing content-type" do
      response =
        JSON.parse(
          lodge_assessment(
            assessment_body: valid_cepc_rr_xml,
            accepted_responses: [400],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            schema_name: nil,
          ).body,
        )

      expect(response["errors"][0]["title"]).to eq(
        'Schema is not defined. Set content-type on the request to "application/xml+RdSAP-Schema-19.0" for example.',
      )
    end

    it "rejects an assessment where the ID already exists" do
      register_assessor
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [409],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )
    end

    it "rejects an assessment where the ID already exists but is cancelled" do
      register_assessor
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      update_assessment_status(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_status_body: {
          status: "CANCELLED",
        },
        auth_data: {
          scheme_ids: [scheme_id],
        },
        accepted_responses: [200],
      )

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [409],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )
    end

    it "rejects an assessment where the ID already exists but is not for issue" do
      register_assessor
      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )

      update_assessment_status(
        assessment_id: "0000-0000-0000-0000-0000",
        assessment_status_body: {
          status: "NOT_FOR_ISSUE",
        },
        auth_data: {
          scheme_ids: [scheme_id],
        },
        accepted_responses: [200],
      )

      lodge_assessment(
        assessment_body: doc.to_xml,
        accepted_responses: [409],
        auth_data: {
          scheme_ids: [scheme_id],
        },
      )
    end

    it "rejects an assessment with an invalid XML element" do
      register_assessor

      doc = Nokogiri.XML valid_rdsap_xml

      node = doc.at("Address")
      node.children = "<Postcode>invalid</Postcode>"
      response_body =
        JSON.parse(
          lodge_assessment(
            assessment_body: doc.to_xml,
            accepted_responses: [400],
            auth_data: {
              scheme_ids: [scheme_id],
            },
          ).body,
        )

      expect(
        response_body["errors"][0]["title"],
      ).to include "This element is not expected."
    end

    it "rejects an assessment with XML that doesnt parse" do
      xml = valid_rdsap_xml
      xml = xml.gsub("<Energy-Assessment>", "<Energy-Assessment")

      response_body =
        JSON.parse(
          lodge_assessment(assessment_body: xml, accepted_responses: [400]).body,
        )

      expect(
        response_body["errors"][0]["title"],
      ).to include "Invalid attribute name: <<Property-Summary>"
    end

    it "rejects a dual lodgement when related RRNs dont match" do
      register_assessor
      xml = Nokogiri.XML valid_cepc_rr_xml
      xml.at("//CEPC:Related-RRN").content = "0000-0000-0000-0000-0002"

      response =
        JSON.parse(
          lodge_assessment(
            assessment_body: xml.to_xml,
            accepted_responses: [400],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            schema_name: "CEPC-8.0.0",
            override: "true",
          ).body,
          symbolize_names: true,
        )

      expect(response[:errors][0][:title]).to eq(
        "Related RRNs must reference each other.",
      )
    end

    it "rejects a dual lodgement when the address ids do not match" do
      register_assessor
      xml = Nokogiri.XML valid_cepc_rr_xml
      xml.at("//CEPC:UPRN").content = "UPRN-111111111111"

      response =
        JSON.parse(
          lodge_assessment(
            assessment_body: xml.to_xml,
            accepted_responses: [400],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            schema_name: "CEPC-8.0.0",
            override: "true",
          ).body,
          symbolize_names: true,
        )

      expect(response[:errors][0][:title]).to eq(
        "Both parts of a dual lodgement must share the same address id.",
      )
    end
  end

  context "when lodging and overriding the rules" do
    let(:cepc_xml_doc) { Nokogiri.XML(valid_cepc_rr_xml) }

    it "logs the events to the overidden_lodgement_events table" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      cepc_xml_doc.at("//CEPC:Registration-Date").children = "2030-05-04"

      lodge_assessment(
        assessment_body: cepc_xml_doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        override: "true",
      )

      overidden_lodgement_event =
        ActiveRecord::Base
          .connection
          .execute(
            "SELECT * FROM overidden_lodgement_events WHERE assessment_id = '0000-0000-0000-0000-0000'",
          )
          .first

      expect(overidden_lodgement_event["assessment_id"]).to eq(
        "0000-0000-0000-0000-0000",
      )
      expect(overidden_lodgement_event["rule_triggers"]).to eq(
        "[{\"code\": \"DATES_CANT_BE_IN_FUTURE\", \"title\": \"Inspection-Date\\\", \\\"Registration-Date\\\", \\\"Issue-Date\\\", \\\"Effective-Date\\\", \\\"OR-Availability-Date\\\", \\\"Start-Date\\\" and \\\"OR-Assessment-Start-Date\\\" must not be in the future\"}]",
      )
    end
  end

  context "when lodging a valid assessment" do
    it "returns the correct response for RdSAP" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment(
            assessment_body: valid_rdsap_xml,
            accepted_responses: [201],
            auth_data: {
              scheme_ids: [scheme_id],
            },
          ).body,
          symbolize_names: true,
        )

      expect(response).to eq(
        {
          data: {
            assessments: %w[0000-0000-0000-0000-0000],
          },
          meta: {
            links: {
              assessments: %w[/api/assessments/0000-0000-0000-0000-0000],
            },
          },
        },
      )
    end

    it "returns the correct response for CEPC+RR" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment(
            assessment_body: valid_cepc_rr_xml,
            accepted_responses: [201],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            schema_name: "CEPC-8.0.0",
          ).body,
          symbolize_names: true,
        )

      expect(response).to eq(
        {
          data: {
            assessments: %w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001],
          },
          meta: {
            links: {
              assessments: %w[
                /api/assessments/0000-0000-0000-0000-0000
                /api/assessments/0000-0000-0000-0000-0001
              ],
            },
          },
        },
      )
    end

    it "returns the correct response for DEC+RR" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment(
            assessment_body: valid_dec_rr_xml,
            accepted_responses: [201],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            schema_name: "CEPC-8.0.0",
          ).body,
          symbolize_names: true,
        )

      expect(response).to eq(
        {
          data: {
            assessments: %w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001],
          },
          meta: {
            links: {
              assessments: %w[
                /api/assessments/0000-0000-0000-0000-0000
                /api/assessments/0000-0000-0000-0000-0001
              ],
            },
          },
        },
      )
    end

    it "returns the correct response for AC-CERT+AC-REPORT" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment(
            assessment_body: valid_ac_cert_report_xml,
            accepted_responses: [201],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            schema_name: "CEPC-8.0.0",
          ).body,
          symbolize_names: true,
        )

      expect(response).to eq(
        {
          data: {
            assessments: %w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001],
          },
          meta: {
            links: {
              assessments: %w[
                /api/assessments/0000-0000-0000-0000-0000
                /api/assessments/0000-0000-0000-0000-0001
              ],
            },
          },
        },
      )
    end

    it "accepts negative current energy rating values for CEPC" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      cepc_xml_doc = Nokogiri.XML(valid_cepc_rr_xml)
      cepc_xml_doc.at("//CEPC:Asset-Rating").children = "-50"

      lodge_assessment(
        assessment_body: cepc_xml_doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )
    end

    it "accepts large current energy efficiency rating values for CEPC" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)

      cepc_xml_doc = Nokogiri.XML(valid_cepc_rr_xml)
      cepc_xml_doc.at("//CEPC:Asset-Rating").children = "-267654"

      lodge_assessment(
        assessment_body: cepc_xml_doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
      )
    end
  end

  context "when migrating an assessment" do
    let(:scheme_id) { add_scheme_and_get_id }

    let(:migrated_column) do
      ActiveRecord::Base.connection.exec_query(
        "SELECT migrated FROM assessments WHERE assessment_id = '0000-0000-0000-0000-0000'",
      )
    end

    before { add_assessor scheme_id, "SPEC000000", valid_assessor_request_body }

    before do
      lodge_assessment assessment_body: valid_rdsap_xml,
                       accepted_responses: [201],
                       scopes: %w[assessment:lodge migrate:assessment],
                       auth_data: {
                         scheme_ids: [scheme_id],
                       },
                       migrated: "true"
    end

    it "should be true in migrated column" do
      expect(migrated_column.entries.first["migrated"]).to be_truthy
    end

    context "when migrating the same assessment ID" do
      before do
        lodge_assessment assessment_body: valid_rdsap_xml,
                         accepted_responses: [201],
                         scopes: %w[assessment:lodge migrate:assessment],
                         auth_data: {
                           scheme_ids: [scheme_id],
                         },
                         migrated: true
      end

      it "should be true in migrated column" do
        expect(migrated_column.entries.first["migrated"]).to be_truthy
      end
    end

    context "when migrating an assessment submitted by an assessor who is now unqualified" do
      let(:rdsap_xml) do
        add_assessor scheme_id,
                     "UNQU000000",
                     AssessorStub.new.fetch_request_body(
                       domesticRdSap: "INACTIVE",
                     )

        xml = Nokogiri.XML valid_rdsap_xml

        xml.css("Certificate-Number").children.first.content = "UNQU000000"

        xml.to_s
      end

      it "should be true in migrated column" do
        lodge_assessment assessment_body: rdsap_xml,
                         accepted_responses: [201],
                         scopes: %w[assessment:lodge migrate:assessment],
                         auth_data: {
                           scheme_ids: [scheme_id],
                         },
                         migrated: true
      end
    end

    it "rejects a migration from a client without migration role" do
      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [403],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: "true",
      )
    end
  end

  context "security" do
    it "returns 401 with no authentication" do
      lodge_assessment(
        assessment_body: "body",
        accepted_responses: [401],
        authenticate: false,
      )
    end

    it "returns 403 with incorrect scopes" do
      lodge_assessment(
        assessment_body: "body",
        accepted_responses: [403],
        auth_data: {
          scheme_ids: {},
        },
        scopes: %w[wrong:scope],
      )
    end

    it "returns 403 if it is being lodged by the wrong scheme" do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, "SPEC000000", valid_assessor_request_body)
      different_scheme_id = add_scheme_and_get_id("BADSCHEME")

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [403],
        auth_data: {
          scheme_ids: [different_scheme_id],
        },
      )
    end
  end
end
