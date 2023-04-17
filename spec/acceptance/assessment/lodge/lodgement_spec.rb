# frozen_string_literal: true

describe "Acceptance::Assessment::Lodge", set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

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

  let(:valid_rdsap_xml) { Samples.xml "RdSAP-Schema-20.0.0" }
  let(:valid_rdsap_ni_xml) { Samples.xml "RdSAP-Schema-NI-20.0.0" }
  let(:valid_cepc_rr_xml) { Samples.xml "CEPC-8.0.0", "cepc+rr" }
  let(:valid_cepc_ni_xml) { Samples.xml "CEPC-NI-8.0.0", "cepc" }
  let(:valid_dec_rr_xml) { Samples.xml "CEPC-8.0.0", "dec+rr" }
  let(:valid_ac_cert_report_xml) do
    Samples.xml "CEPC-8.0.0", "ac-cert+ac-report"
  end
  let(:scheme_id) { add_scheme_and_get_id }

  context "when rejecting lodgements" do
    let(:scheme_id) { add_scheme_and_get_id }
    let(:doc) { Nokogiri.XML valid_rdsap_xml }
    let(:register_assessor) do
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: valid_assessor_request_body)
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

      expect(response_body["errors"][0]["code"]).to eq "INVALID_REQUEST"
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

    it "rejects an assessment with an NI RdSAP schema an not a BT postcode" do
      register_assessor
      xml = Nokogiri.XML valid_rdsap_ni_xml
      xml.at("RRN").content = "9999-0000-0000-0000-0000"
      xml.xpath("//*[local-name() = 'Postcode']").each { |node| node.content = "SW1 0AA" }
      response =
        JSON.parse(
          lodge_assessment(
            assessment_body: xml.to_xml,
            accepted_responses: [400],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            schema_name: "RdSAP-Schema-NI-20.0.0",
          ).body,
          migrated: false,
          override: false,
        )

      expect(response["errors"]).to eq("Assessment with a Northern Ireland schema must have a property postcode starting with BT")
    end

    it "rejects an assessment with an a BT postcode and non NI schema" do
      register_assessor
      xml = Nokogiri.XML valid_rdsap_xml
      xml.at("RRN").content = "9999-0000-0000-0000-0000"
      xml.xpath("//*[local-name() = 'Postcode']").each { |node| node.content = "BT7 0AA" }
      response =
        JSON.parse(
          lodge_assessment(
            assessment_body: xml.to_xml,
            accepted_responses: [400],
            auth_data: {
              scheme_ids: [scheme_id],
            },
            schema_name: "RdSAP-Schema-20.0.0",
          ).body,
          migrated: false,
          override: false,
        )

      expect(response["errors"]).to eq("Assessment with a Northern Ireland postcode must be lodged with a NI Schema")
    end
  end

  context "when lodging and overriding the rules" do
    let(:cepc_xml_doc) { Nokogiri.XML(valid_cepc_rr_xml) }

    before do
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: valid_assessor_request_body)
    end

    it "logs the events to the overridden_lodgement_events table" do
      cepc_xml_doc.at("//CEPC:Inspection-Date").children = "2006-05-04"

      lodge_assessment(
        assessment_body: cepc_xml_doc.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "CEPC-8.0.0",
        override: "true",
      )

      overridden_lodgement_event =
        ActiveRecord::Base
          .connection
          .execute(
            "SELECT * FROM overridden_lodgement_events WHERE assessment_id = '0000-0000-0000-0000-0000'",
          )
          .first

      expect(overridden_lodgement_event["assessment_id"]).to eq(
        "0000-0000-0000-0000-0000",
      )
      expect(overridden_lodgement_event["rule_triggers"]).to eq(
        '[{"code": "DATES_CANT_BE_MORE_THAN_4_YEARS_AGO", "title": "\\"Inspection-Date\\", \\"Registration-Date\\" and \\"Issue-Date\\" must not be more than 4 years ago"}]',
      )
    end

    it "updates the addressId to the default address id when it's lodged with LPRN-based addressId" do
      rdsap = Nokogiri.XML(Samples.xml("RdSAP-Schema-17.0"))
      rdsap.at("RRN").children = "0000-0000-0000-0000-0001"
      rdsap.at("UPRN").children = "1234567890"

      lodge_assessment(
        assessment_body: rdsap.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
        override: true,
        schema_name: "RdSAP-Schema-17.0",
      )

      response = get_assessment_summary("0000-0000-0000-0000-0001")

      expect(response[:data][:address][:addressId]).to eq("RRN-0000-0000-0000-0000-0001")
    end
  end

  context "when lodging a valid assessment" do
    before do
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: valid_assessor_request_body)
    end

    it "returns the correct response for RdSAP" do
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

    it "contains the hashed assessment id in the hashed_assessment_id column" do
      lodge_assessment assessment_body: valid_rdsap_xml,
                       accepted_responses: [201],
                       scopes: %w[assessment:lodge],
                       auth_data: {
                         scheme_ids: [scheme_id],
                       },
                       migrated: "false"

      hashed_assessment_id_column = ActiveRecord::Base.connection.exec_query("SELECT hashed_assessment_id FROM assessments WHERE assessment_id = '0000-0000-0000-0000-0000'")

      expect(hashed_assessment_id_column.entries.first["hashed_assessment_id"]).to eq("4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a")
    end

    it "accepts negative current energy rating values for CEPC" do
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

    context "when given an assessment with an NI schema and a BT postcode" do
      before do
        map_lookups_to_country_codes { %w[N] } # 'N' for Northern Ireland
      end

      it "accepts the lodgement" do
        xml_doc = Nokogiri.XML(valid_cepc_ni_xml)
        lodge_assessment(
          assessment_body: xml_doc.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          schema_name: "CEPC-NI-8.0.0",
        )
      end
    end

    context "when validating and adjusting the addressId" do
      let(:assessments_address_id_gateway) do
        Gateway::AssessmentsAddressIdGateway.new
      end

      describe "domestic EPC" do
        context "when an assessment is lodged with a valid addressId" do
          let!(:response) do
            lodge_and_fetch_assessment(
              rrn_node: "0000-0000-0000-0000-0001",
              uprn_node: "RRN-0000-0000-0000-0000-0001",
            )
          end

          context "when the UPRN exists in the the address_base" do
            it "persists the original UPRN addressId if it exists in the address base" do
              response =
                lodge_and_fetch_assessment(
                  rrn_node: "0000-0000-0000-0000-0002",
                  uprn_node: "UPRN-000000000001",
                )

              expect(response[:data][:address][:addressId]).to eq("UPRN-000000000001")
            end
          end

          it "doesn't update the addressId if it's lodged with a correct default RRN-based addressId" do
            expect(response[:data][:address][:addressId]).to eq(
              "RRN-0000-0000-0000-0000-0001",
            )
          end

          it "saves source as 'lodgement'" do
            response =
              assessments_address_id_gateway.fetch("0000-0000-0000-0000-0001")

            expect(response[:source]).to eq("lodgement")
          end
        end

        context "when an assessment is lodged with an invalid addressId" do
          it "saves source as 'adjusted_at_lodgement'" do
            lodge_and_fetch_assessment(
              rrn_node: "0000-0000-0000-0000-0001",
              uprn_node: "UPRN-000000000000",
              ensure_uprns: false,
            )

            response =
              assessments_address_id_gateway.fetch("0000-0000-0000-0000-0001")

            expect(response[:source]).to eq("adjusted_at_lodgement")
          end

          it "updates the addressId to the default address id when RRN-based addressId doesn't correspond to an existing assessment id" do
            response =
              lodge_and_fetch_assessment(
                rrn_node: "0000-0000-0000-0000-0001",
                uprn_node: "RRN-0000-0000-0000-0000-9999",
              )

            expect(response[:data][:address][:addressId]).to eq(
              "RRN-0000-0000-0000-0000-0001",
            )
          end

          it "updates the addressId to the default address id when it doesn't exist in the address base" do
            response =
              lodge_and_fetch_assessment(
                rrn_node: "0000-0000-0000-0000-0001",
                uprn_node: "UPRN-000000000000",
                ensure_uprns: false,
              )

            expect(response[:data][:address][:addressId]).to eq(
              "RRN-0000-0000-0000-0000-0001",
            )
          end

          it "updates the addressId to the RRN-based addressId of an existing assessmeent when trying to link with RRN of the previous assessment" do
            lodge_and_fetch_assessment(
              rrn_node: "0000-0000-0000-0000-0000",
              uprn_node: "RRN-0000-0000-0000-0000-0000",
            )
            lodge_and_fetch_assessment(
              rrn_node: "0000-0000-0000-0000-0001",
              uprn_node: "RRN-0000-0000-0000-0000-0000",
            )

            response =
              lodge_and_fetch_assessment(
                rrn_node: "0000-0000-0000-0000-0002",
                uprn_node: "RRN-0000-0000-0000-0000-0001",
              )

            expect(response[:data][:address][:addressId]).to eq(
              "RRN-0000-0000-0000-0000-0000",
            )
          end

          it "updates the addressId to the UPRN-based addressId of an existing assessmeent when trying to link with RRN" do
            gateway = instance_double(Gateway::AddressBaseSearchGateway)
            allow(Gateway::AddressBaseSearchGateway).to receive(:new)
              .and_return(gateway)
            allow(gateway).to receive(:check_uprn_exists)
              .with("000000000001")
              .and_return(true)

            lodge_and_fetch_assessment(
              rrn_node: "0000-0000-0000-0000-0000",
              uprn_node: "UPRN-000000000001",
            )

            response =
              lodge_and_fetch_assessment(
                rrn_node: "0000-0000-0000-0000-0001",
                uprn_node: "RRN-0000-0000-0000-0000-0000",
              )

            expect(response[:data][:address][:addressId]).to eq("UPRN-000000000001")
          end
        end
      end

      describe "CEPC RR (dual lodgements)" do
        context "when an assessment is lodged with a valid addressId" do
          let!(:first_assessment) do
            lodge_and_fetch_non_domestic_assessment(
              rrn_node: "0000-0000-0000-0000-0001",
              uprn_node: "RRN-0000-0000-0000-0000-0001",
              related_rrn_node: "0000-0000-0000-0000-0000",
            )
          end

          it "doesn't update the addressId if it's lodged with a correct default RRN-based addressId" do
            second_assessment =
              get_assessment_summary("0000-0000-0000-0000-0000")

            expect(first_assessment[:data][:address][:addressId]).to eq(
              "RRN-0000-0000-0000-0000-0001",
            )
            expect(second_assessment[:data][:address][:addressId]).to eq(
              "RRN-0000-0000-0000-0000-0001",
            )
          end

          it "persists the original UPRN addressId if it exists in the address base" do
            first_assessment =
              lodge_and_fetch_non_domestic_assessment(
                rrn_node: "0000-0000-0000-0000-0008",
                uprn_node: "UPRN-000000000001",
                related_rrn_node: "0000-0000-0000-0000-0009",
              )

            second_assessment =
              get_assessment_summary("0000-0000-0000-0000-0009")

            expect(first_assessment[:data][:address][:addressId]).to eq(
              "UPRN-000000000001",
            )
            expect(second_assessment[:data][:address][:addressId]).to eq(
              "UPRN-000000000001",
            )
          end

          it "saves source as 'lodgement'" do
            first_assessment =
              assessments_address_id_gateway.fetch("0000-0000-0000-0000-0001")
            second_assessment =
              assessments_address_id_gateway.fetch("0000-0000-0000-0000-0000")

            expect(first_assessment[:source]).to eq("lodgement")
            expect(second_assessment[:source]).to eq("lodgement")
          end
        end

        context "when an assessment is lodged with an invalid addressId" do
          let!(:first_assessment) do
            lodge_and_fetch_non_domestic_assessment(
              rrn_node: "0000-0000-0000-0000-0001",
              uprn_node: "RRN-0000-0000-0000-0000-0007",
              related_rrn_node: "0000-0000-0000-0000-0000",
              ensure_uprns: false,
            )
          end

          it "saves source as 'adjusted_at_lodgement'" do
            first_response =
              assessments_address_id_gateway.fetch("0000-0000-0000-0000-0001")
            second_response =
              assessments_address_id_gateway.fetch("0000-0000-0000-0000-0000")

            expect(first_response[:source]).to eq("adjusted_at_lodgement")
            expect(second_response[:source]).to eq("adjusted_at_lodgement")
          end

          it "updates the addressId to the default address id when RRN-based addressId doesn't correspond to an existing assessment id for CEPC+RR" do
            second_assessment =
              get_assessment_summary("0000-0000-0000-0000-0000")
            expect(first_assessment[:data][:address][:addressId]).to eq(
              "RRN-0000-0000-0000-0000-0001",
            )
            expect(second_assessment[:data][:address][:addressId]).to eq(
              "RRN-0000-0000-0000-0000-0001",
            )
          end

          it "updates the addressId to the default address id when it doesn't exist in the address base" do
            first_assessment =
              lodge_and_fetch_non_domestic_assessment(
                rrn_node: "0000-0000-0000-0000-0009",
                uprn_node: "UPRN-000000000000",
                related_rrn_node: "0000-0000-0000-0000-0008",
                ensure_uprns: false,
              )
            second_assessment =
              get_assessment_summary("0000-0000-0000-0000-0008")

            expect(first_assessment[:data][:address][:addressId]).to eq(
              "RRN-0000-0000-0000-0000-0009",
            )
            expect(second_assessment[:data][:address][:addressId]).to eq(
              "RRN-0000-0000-0000-0000-0009",
            )
          end

          it "updates the addressId to the RRN-based addressId of an existing assessment when trying to link with RRN of the previous assessment" do
            lodge_and_fetch_non_domestic_assessment(
              rrn_node: "0000-0000-0000-0000-0011",
              uprn_node: "RRN-0000-0000-0000-0000-0011",
              related_rrn_node: "0000-0000-0000-0000-0022",
            )
            lodge_and_fetch_non_domestic_assessment(
              rrn_node: "0000-0000-0000-0000-0033",
              uprn_node: "RRN-0000-0000-0000-0000-0011",
              related_rrn_node: "0000-0000-0000-0000-0044",
            )

            first_assessment =
              lodge_and_fetch_non_domestic_assessment(
                rrn_node: "0000-0000-0000-0000-0055",
                uprn_node: "RRN-0000-0000-0000-0000-0022",
                related_rrn_node: "0000-0000-0000-0000-0066",
              )

            second_assessment =
              get_assessment_summary("0000-0000-0000-0000-0066")

            expect(first_assessment[:data][:address][:addressId]).to eq(
              "RRN-0000-0000-0000-0000-0011",
            )
            expect(second_assessment[:data][:address][:addressId]).to eq(
              "RRN-0000-0000-0000-0000-0011",
            )
          end

          it "updates the addressId to the UPRN-based addressId of an existing assessment when trying to link with RRN" do
            gateway = instance_double(Gateway::AddressBaseSearchGateway)
            allow(Gateway::AddressBaseSearchGateway).to receive(:new)
              .and_return(gateway)
            allow(gateway).to receive(:check_uprn_exists)
              .with("000000000001")
              .and_return(true)

            lodge_and_fetch_non_domestic_assessment(
              rrn_node: "0000-0000-0000-0000-1111",
              uprn_node: "UPRN-000000000001",
              related_rrn_node: "0000-0000-0000-0000-2222",
            )

            first_assessment =
              lodge_and_fetch_non_domestic_assessment(
                rrn_node: "0000-0000-0000-0000-3333",
                uprn_node: "RRN-0000-0000-0000-0000-1111",
                related_rrn_node: "0000-0000-0000-0000-4444",
              )

            second_assessment =
              get_assessment_summary("0000-0000-0000-0000-4444")

            expect(first_assessment[:data][:address][:addressId]).to eq(
              "UPRN-000000000001",
            )
            expect(second_assessment[:data][:address][:addressId]).to eq(
              "UPRN-000000000001",
            )
          end
        end
      end
    end
  end

  context "when migrating an assessment" do
    let(:scheme_id) { add_scheme_and_get_id }

    let(:migrated_column) do
      ActiveRecord::Base.connection.exec_query(
        "SELECT migrated FROM assessments WHERE assessment_id = '0000-0000-0000-0000-0000'",
      )
    end

    before do
      add_assessor scheme_id:, assessor_id: "SPEC000000", body: valid_assessor_request_body
      lodge_assessment assessment_body: valid_rdsap_xml,
                       accepted_responses: [201],
                       scopes: %w[assessment:lodge migrate:assessment],
                       auth_data: {
                         scheme_ids: [scheme_id],
                       },
                       migrated: "true"
    end

    it "is true in migrated column" do
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

      it "is true in migrated column" do
        expect(migrated_column.entries.first["migrated"]).to be_truthy
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

        xml.css("Certificate-Number").children.first.content = "UNQU000000"

        xml.to_s
      end

      it "is true in migrated column" do
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
        scopes: %w[assessment:lodge],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        migrated: true,
      )
    end
  end

  context "when lodging an assessment of a superseded schema version that is not marked migrated" do
    it "rejects the assessment with a 400" do
      superseded_version = "RdSAP-Schema-19.0"

      lodge_assessment(
        assessment_body: Samples.xml(superseded_version),
        accepted_responses: [400],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: superseded_version,
      )
    end
  end

  context "when lodging an assessment for SAP-Schema-19.0.0 which has an invalid SAP data version" do
    let(:bad_sap_1900_data_version_xml) do
      xml = Nokogiri.XML Samples.xml("SAP-Schema-19.0.0")
      xml.at("SAP-Data-Version").content = "9.90"

      xml.to_s
    end

    let(:register_assessor) do
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: valid_assessor_request_body)
    end

    it "rejects the assessment with a 400" do
      register_assessor
      lodge_assessment(
        assessment_body: bad_sap_1900_data_version_xml,
        accepted_responses: [400],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "SAP-Schema-19.0.0",
      )
    end
  end

  context "when lodging an assessment for SAP-Schema-19.1.0 which has an invalid SAP data version" do
    let(:bad_sap_1910_data_version_xml) do
      xml = Nokogiri.XML Samples.xml("SAP-Schema-19.1.0")
      xml.at("SAP-Data-Version").content = "9.90"

      xml.to_s
    end

    let(:register_assessor) do
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: valid_assessor_request_body)
    end

    it "rejects the assessment with a 400" do
      register_assessor
      lodge_assessment(
        assessment_body: bad_sap_1910_data_version_xml,
        accepted_responses: [400],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: "SAP-Schema-19.1.0",
      )
    end
  end

  describe "security" do
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
      add_assessor(scheme_id:, assessor_id: "SPEC000000", body: valid_assessor_request_body)
      different_scheme_id = add_scheme_and_get_id(name: "BADSCHEME")

      lodge_assessment(
        assessment_body: valid_rdsap_xml,
        accepted_responses: [403],
        auth_data: {
          scheme_ids: [different_scheme_id],
        },
      )
    end
  end

  def lodge_and_fetch_assessment(rrn_node:, uprn_node:, xml: valid_rdsap_xml, ensure_uprns: true)
    assessment = Nokogiri.XML(xml)
    assessment.at("RRN").children = rrn_node
    assessment.at("UPRN").children = uprn_node

    lodge_assessment(
      assessment_body: assessment.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      ensure_uprns:,
    )

    get_assessment_summary(rrn_node)
  end

  def lodge_and_fetch_non_domestic_assessment(
    rrn_node:,
    uprn_node:,
    related_rrn_node:,
    ensure_uprns: true
  )
    assessment = Nokogiri.XML(valid_cepc_rr_xml)
    assessment.xpath("//CEPC:RRN").children.first.content = rrn_node
    assessment.xpath("//CEPC:RRN").children.last.content = related_rrn_node

    assessment.xpath("//CEPC:UPRN").children.first.content = uprn_node
    assessment.xpath("//CEPC:UPRN").children.last.content = uprn_node

    assessment.xpath("//CEPC:Related-RRN").children.first.content =
      related_rrn_node
    assessment.xpath("//CEPC:Related-RRN").children.last.content = rrn_node

    lodge_assessment(
      assessment_body: assessment.to_xml,
      accepted_responses: [201],
      auth_data: {
        scheme_ids: [scheme_id],
      },
      schema_name: "CEPC-8.0.0",
      ensure_uprns:,
    )

    get_assessment_summary(rrn_node)
  end

  def get_assessment_summary(assessment_id)
    JSON.parse(
      fetch_assessment_summary(id: assessment_id).body,
      symbolize_names: true,
    )
  end
end
