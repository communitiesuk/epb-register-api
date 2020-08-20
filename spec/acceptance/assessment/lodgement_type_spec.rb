# frozen_string_literal: true

describe "Acceptance::Assessment::LodgementType" do
  include RSpecRegisterApiServiceMixin

  def vcr(filename, expected_response, folder = "responses", filetype = ".json")
    path = "spec/fixtures/" + folder + "/" + filename + filetype
    if File.file?(path)
      JSON.parse((File.read File.join Dir.pwd, path), symbolize_names: true)
    else
      Dir.mkdir File.dirname path unless Dir.exist? File.dirname path

      File.write(path, expected_response.to_json)

      vcr(filename, expected_response, folder, filetype)
    end
  end

  let(:scheme_id) { add_scheme_and_get_id }

  def create_assessor(qualifications)
    add_assessor(
      scheme_id,
      "SPEC000000",
      AssessorStub.new.fetch_request_body(qualifications),
    )
  end

  def get_lodgement(xml_name, response_code, schema_name, migrate = nil)
    JSON.parse(
      lodge_assessment(
        assessment_body: Samples.xml(schema_name.to_s, xml_name),
        accepted_responses: response_code,
        auth_data: { scheme_ids: [scheme_id] },
        schema_name: schema_name.to_s,
        scopes:
          (
            if migrate.nil?
              %w[assessment:lodge]
            else
              %w[assessment:lodge migrate:assessment]
            end
          ),
        migrated: migrate,
      ).body,
      symbolize_names: true,
    )
  end

  context "when lodging all assessment types" do
    assessments = {
      "RdSAP-Schema-NI-20.0.0": {
        "valid_rdsap": {
          xml: "epc",
          expected_lodgement_responses: { "0000-0000-0000-0000-0000": "rdsap" },
          assessor_qualification: { domesticRdSap: "ACTIVE" },
        },
      },
      "RdSAP-Schema-20.0.0": {
        "valid_rdsap": {
          xml: "epc",
          expected_lodgement_responses: {
            "0000-0000-0000-0000-0000": "rdsap-ni",
          },
          assessor_qualification: { domesticRdSap: "ACTIVE" },
        },
      },
      "SAP-Schema-NI-18.0.0": {
        "valid_sap": {
          xml: "epc",
          expected_lodgement_responses: {
            "0000-0000-0000-0000-0000": "sap-ni",
          },
          assessor_qualification: { domesticSap: "ACTIVE" },
        },
      },
      "SAP-Schema-18.0.0": {
        "valid_sap": {
          xml: "epc",
          expected_lodgement_responses: { "0000-0000-0000-0000-0000": "sap" },
          assessor_qualification: { domesticSap: "ACTIVE" },
        },
      },
      "CEPC-7.1": {
        "valid_cepc": {
          xml: "cepc",
          assessor_qualification: {
            nonDomesticNos3: "ACTIVE",
            nonDomesticNos4: "ACTIVE",
            nonDomesticNos5: "ACTIVE",
          },
          migrate: true,
          expected_lodgement_responses: {
            "0000-0000-0000-0000-0000": "CEPC-7.1/cepc",
          },
        },
        "valid_cepc+rr": {
          xml: "cepc+rr",
          assessor_qualification: {
            nonDomesticNos3: "ACTIVE",
            nonDomesticNos4: "ACTIVE",
            nonDomesticNos5: "ACTIVE",
          },
          expected_response: "dual_lodgement",
          expected_lodgement_responses: {
            "0000-0000-0000-0000-0000": "CEPC-7.1/cepc-dual",
            "0000-0000-0000-0000-0001": "CEPC-7.1/cepc-rr-dual",
          },
          migrate: true,
        },
        "valid_dec": {
          xml: "dec",
          assessor_qualification: { nonDomesticDec: "ACTIVE" },
          expected_lodgement_responses: {
            "0000-0000-0000-0000-0000": "CEPC-7.1/dec",
          },
          migrate: true,
        },
        "valid_dec+rr": {
          xml: "dec+rr",
          assessor_qualification: { nonDomesticDec: "ACTIVE" },
          expected_response: "dual_lodgement",
          expected_lodgement_responses: {
            "0000-0000-0000-0000-0000": "CEPC-7.1/dec-dual",
            "0000-0000-0000-0000-0001": "CEPC-7.1/dec-rr-dual",
          },
          migrate: true,
        },
        "valid_rr": {
          xml: "cepc-rr",
          assessor_qualification: {
            nonDomesticNos3: "ACTIVE",
            nonDomesticNos4: "ACTIVE",
            nonDomesticNos5: "ACTIVE",
          },
          expected_lodgement_responses: {
            "0000-0000-0000-0000-0000": "CEPC-7.1/cepc-rr",
          },
          migrate: true,
        },
      },
      "CEPC-8.0.0": {
        "valid_cepc": {
          xml: "cepc",
          assessor_qualification: {
            nonDomesticNos3: "ACTIVE",
            nonDomesticNos4: "ACTIVE",
            nonDomesticNos5: "ACTIVE",
          },
        },
        "valid_cepc+rr": {
          xml: "cepc+rr",
          assessor_qualification: {
            nonDomesticNos3: "ACTIVE",
            nonDomesticNos4: "ACTIVE",
            nonDomesticNos5: "ACTIVE",
          },
          expected_response: "dual_lodgement",
          expected_lodgement_responses: {
            "0000-0000-0000-0000-0000": "cepc-dual",
            "0000-0000-0000-0000-0001": "cepc-rr-dual",
          },
        },
        "valid_dec": {
          xml: "dec", assessor_qualification: { nonDomesticDec: "ACTIVE" }
        },
        "valid_dec+rr": {
          xml: "dec+rr",
          assessor_qualification: { nonDomesticDec: "ACTIVE" },
          expected_response: "dual_lodgement",
          expected_lodgement_responses: {
            "0000-0000-0000-0000-0000": "dec-dual",
            "0000-0000-0000-0000-0001": "dec-rr-dual",
          },
        },
        "valid_rr": {
          xml: "cepc-rr",
          assessor_qualification: {
            nonDomesticNos3: "ACTIVE",
            nonDomesticNos4: "ACTIVE",
            nonDomesticNos5: "ACTIVE",
          },
        },
        "valid_ac-report": {
          xml: "ac-report", assessor_qualification: { nonDomesticSp3: "ACTIVE" }
        },
        "valid_ac-cert": {
          xml: "ac-cert", assessor_qualification: { nonDomesticCc4: "ACTIVE" }
        },
        "valid_ac-cert+ac-report": {
          xml: "ac-cert+ac-report",
          assessor_qualification: {
            nonDomesticCc4: "ACTIVE", nonDomesticSp3: "ACTIVE"
          },
          expected_response: "dual_lodgement",
          expected_lodgement_responses: {
            "0000-0000-0000-0000-0000": "ac-cert-dual",
            "0000-0000-0000-0000-0001": "ac-report-dual",
          },
        },
      },
      "CEPC-NI-8.0.0": {
        "valid_cepc": {
          xml: "cepc",
          assessor_qualification: {
            nonDomesticNos3: "ACTIVE",
            nonDomesticNos4: "ACTIVE",
            nonDomesticNos5: "ACTIVE",
          },
        },
        "valid_cepc+rr": {
          xml: "cepc+rr",
          assessor_qualification: {
            nonDomesticNos3: "ACTIVE",
            nonDomesticNos4: "ACTIVE",
            nonDomesticNos5: "ACTIVE",
          },
          expected_response: "dual_lodgement",
          expected_lodgement_responses: {
            "0000-0000-0000-0000-0000": "cepc-ni-dual",
            "0000-0000-0000-0000-0001": "cepc-rr-ni-dual",
          },
        },
        "valid_dec": {
          xml: "dec", assessor_qualification: { nonDomesticDec: "ACTIVE" }
        },
        "valid_dec+rr": {
          xml: "dec+rr",
          assessor_qualification: { nonDomesticDec: "ACTIVE" },
          expected_response: "dual_lodgement",
          expected_lodgement_responses: {
            "0000-0000-0000-0000-0000": "dec-ni-dual",
            "0000-0000-0000-0000-0001": "dec-rr-ni-dual",
          },
        },
        "valid_rr": {
          xml: "cepc-rr",
          assessor_qualification: {
            nonDomesticNos3: "ACTIVE",
            nonDomesticNos4: "ACTIVE",
            nonDomesticNos5: "ACTIVE",
          },
        },
        "valid_ac-report": {
          xml: "ac-report", assessor_qualification: { nonDomesticSp3: "ACTIVE" }
        },
        "valid_ac-cert": {
          xml: "ac-cert", assessor_qualification: { nonDomesticCc4: "ACTIVE" }
        },
        "valid_ac-cert+ac-report": {
          xml: "ac-cert+ac-report",
          assessor_qualification: {
            nonDomesticCc4: "ACTIVE", nonDomesticSp3: "ACTIVE"
          },
          expected_response: "dual_lodgement",
          expected_lodgement_responses: {
            "0000-0000-0000-0000-0000": "ac-cert-ni-dual",
            "0000-0000-0000-0000-0001": "ac-report-ni-dual",
          },
        },
      },
    }

    assessments.each do |schema_name, assessments|
      context "when lodging with schema " + schema_name.to_s do
        assessments.each do |assessment_name, assessment_settings|
          context "when assessment is a #{assessment_name}" do
            if assessment_settings[:response_code].nil?
              assessment_settings[:response_code] = [201]
            end

            if assessment_settings[:expected_response].nil?
              assessment_settings[:expected_response] = "lodgement"
            end

            if assessment_settings[:expected_lodgement_responses].nil?
              assessment_settings[:expected_lodgement_responses] = {
                "0000-0000-0000-0000-0000": assessment_settings[:xml],
              }
            end

            it "tries to lodge a " + assessment_name.to_s +
              " with response code " +
              assessment_settings[:response_code].join(", ") do
              create_assessor(assessment_settings[:assessor_qualification])

              lodgement_response =
                get_lodgement(
                  assessment_settings[:xml],
                  assessment_settings[:response_code],
                  schema_name,
                  assessment_settings[:migrate] || nil,
                )

              if assessment_settings[:expected_response]
                expect(lodgement_response).to eq(
                  vcr(
                    assessment_settings[:expected_response],
                    lodgement_response,
                  ),
                )
              end

              assessment_settings[:expected_lodgement_responses]
                .each do |rrn, filename|
                fetch_endpoint_response =
                  JSON.parse(
                    fetch_assessment_summary(rrn).body,
                    symbolize_names: true,
                  )

                unless fetch_endpoint_response.dig(
                  :data,
                  :assessor,
                  :registeredBy,
                  :schemeId,
                ).nil?
                  fetch_endpoint_response[:data][:assessor][:registeredBy][
                    :schemeId
                  ] =
                    "{schemeId}"
                end

                expected_fetch_endpoint_response =
                  vcr(filename, fetch_endpoint_response)

                expect(fetch_endpoint_response).to eq(
                  expected_fetch_endpoint_response,
                )
              end
            end

            if assessment_settings[:dont_check_incorrect_assessor].nil?
              it "gives error 400 when lodging with insufficient qualification" do
                create_assessor({})

                lodgement_response =
                  get_lodgement(assessment_settings[:xml], [400], schema_name)

                expect(lodgement_response[:errors][0][:title]).to eq(
                  "Assessor is not active.",
                )
              end
            end

            next unless assessment_settings[:dont_cancel_assessment].nil?

            it "can cancel the report " + assessment_name.to_s do
              create_assessor(assessment_settings[:assessor_qualification])

              get_lodgement(assessment_settings[:xml], [201], schema_name)

              assessment_settings[:expected_lodgement_responses]
                .each do |rrn, _|
                assessment_status =
                  JSON.parse(
                    update_assessment_status(
                      assessment_id: rrn.to_s,
                      assessment_status_body: { "status": "CANCELLED" },
                      accepted_responses: [200],
                      auth_data: { scheme_ids: [scheme_id] },
                    ).body,
                    symbolize_names: true,
                  )

                expect(assessment_status).to eq(
                  vcr("cancelled_assessment", assessment_status),
                )

                fetch_assessment_summary(rrn, [410])
              end
            end

            it "can change report type " + assessment_name.to_s +
              " to NOT_FOR_ISSUE" do
              create_assessor(assessment_settings[:assessor_qualification])

              get_lodgement(assessment_settings[:xml], [201], schema_name)

              assessment_settings[:expected_lodgement_responses]
                .each do |rrn, _|
                assessment_status =
                  JSON.parse(
                    update_assessment_status(
                      assessment_id: rrn.to_s,
                      assessment_status_body: { "status": "NOT_FOR_ISSUE" },
                      accepted_responses: [200],
                      auth_data: { scheme_ids: [scheme_id] },
                    ).body,
                    symbolize_names: true,
                  )

                expect(assessment_status).to eq(
                  vcr("not_for_issue_assessment", assessment_status),
                )

                fetch_assessment_summary(rrn, [410])
              end
            end
          end
        end
      end
    end
  end
end
