# frozen_string_literal: true

describe "Acceptance::Assessment::QualificationAndStatusPerType",
         set_with_timecop: true do
  include RSpecRegisterApiServiceMixin

  def sample(name, schema_name)
    File.read File.join Dir.pwd,
                        "spec/fixtures/samples/#{schema_name}/#{name}.xml"
  end

  let(:scheme_id) { add_scheme_and_get_id }

  def create_assessor(qualifications)
    add_assessor(
      scheme_id: scheme_id,
      assessor_id: "SPEC000000",
      body: AssessorStub.new.fetch_request_body(**qualifications),
    )
  end

  def get_lodgement(xml_name, response_code, schema_name)
    JSON.parse(
      lodge_assessment(
        assessment_body: sample(xml_name, schema_name.to_s),
        accepted_responses: response_code,
        auth_data: {
          scheme_ids: [scheme_id],
        },
        schema_name: schema_name.to_s,
      ).body,
      symbolize_names: true,
    )
  end

  context "when lodging all assessment types" do
    assessments = {
      "RdSAP-Schema-20.0.0": {
        "valid_rdsap": {
          xml: "epc",
          assessor_qualification: {
            domestic_rd_sap: "ACTIVE",
          },
        },
      },
      "SAP-Schema-18.0.0": {
        "valid_sap": {
          xml: "epc",
          assessor_qualification: {
            domestic_sap: "ACTIVE",
          },
        },
      },
      "CEPC-8.0.0": {
        "valid_cepc": {
          xml: "cepc",
          assessor_qualification: {
            non_domestic_nos3: "ACTIVE",
            non_domestic_nos4: "ACTIVE",
            non_domestic_nos5: "ACTIVE",
          },
        },
        "valid_cepc+rr": {
          xml: "cepc+rr",
          assessor_qualification: {
            non_domestic_nos3: "ACTIVE",
            non_domestic_nos4: "ACTIVE",
            non_domestic_nos5: "ACTIVE",
          },
          expected_response: "dual_lodgement",
          lodged_rrns: %w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001],
        },
        "valid_dec": {
          xml: "dec",
          assessor_qualification: {
            non_domestic_dec: "ACTIVE",
          },
        },
        "valid_dec+rr": {
          xml: "dec+rr",
          assessor_qualification: {
            non_domestic_dec: "ACTIVE",
          },
          expected_response: "dual_lodgement",
          lodged_rrns: %w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001],
        },
        "valid_rr": {
          xml: "cepc-rr",
          assessor_qualification: {
            non_domestic_nos3: "ACTIVE",
            non_domestic_nos4: "ACTIVE",
            non_domestic_nos5: "ACTIVE",
          },
        },
        "valid_ac-report": {
          xml: "ac-report",
          assessor_qualification: {
            non_domestic_sp3: "ACTIVE",
            non_domestic_cc4: "ACTIVE",
          },
        },
        "valid_ac-cert": {
          xml: "ac-cert",
          assessor_qualification: {
            non_domestic_sp3: "ACTIVE",
            non_domestic_cc4: "ACTIVE",
          },
        },
        "valid_ac-cert+ac-report": {
          xml: "ac-cert+ac-report",
          assessor_qualification: {
            non_domestic_cc4: "ACTIVE",
            non_domestic_sp3: "ACTIVE",
          },
          expected_response: "dual_lodgement",
          lodged_rrns: %w[0000-0000-0000-0000-0000 0000-0000-0000-0000-0001],
        },
      },
    }

    assessments.each do |schema_name, schema_assessments|
      context "when lodging with schema #{schema_name}" do
        schema_assessments.each do |assessment_name, assessment_settings|
          if assessment_settings[:response_code].nil?
            assessment_settings[:response_code] = [201]
          end

          if assessment_settings[:expected_response].nil?
            assessment_settings[:expected_response] = "lodgement"
          end

          if assessment_settings[:lodged_rrns].nil?
            assessment_settings[:lodged_rrns] = %w[0000-0000-0000-0000-0000]
          end

          it "tries to lodge a #{assessment_name} with response code #{assessment_settings[:response_code].join(', ')}" do
            create_assessor(assessment_settings[:assessor_qualification])

            get_lodgement(
              assessment_settings[:xml],
              assessment_settings[:response_code],
              schema_name,
            )
          end

          if assessment_settings[:dont_check_incorrect_assessor].nil?
            it "gives error 400 when lodging with insufficient qualification" do
              create_assessor(
                {
                  non_domestic_nos3: "INACTIVE",
                  non_domestic_nos4: "SUSPENDED",
                  non_domestic_nos5: "INACTIVE",
                  non_domestic_dec: "SUSPENDED",
                  domestic_rd_sap: "INACTIVE",
                  domestic_sap: "SUSPENDED",
                  non_domestic_sp3: "INACTIVE",
                  non_domestic_cc4: "INACTIVE",
                  gda: "INACTIVE",
                },
              )

              lodgement_response =
                get_lodgement(assessment_settings[:xml], [400], schema_name)

              expect(lodgement_response[:errors][0][:title]).to eq(
                "Assessor is not active.",
              )
            end
          end

          it "can cancel the report #{assessment_name}" do
            create_assessor(assessment_settings[:assessor_qualification])

            get_lodgement(assessment_settings[:xml], [201], schema_name)

            first_rrn = assessment_settings[:lodged_rrns].first
            assessment_status =
              JSON.parse(
                update_assessment_status(
                  assessment_id: first_rrn.to_s,
                  assessment_status_body: {
                    "status": "CANCELLED",
                  },
                  accepted_responses: [200],
                  auth_data: {
                    scheme_ids: [scheme_id],
                  },
                ).body,
                symbolize_names: true,
              )
            expect(assessment_status[:data]).to eq({ status: "CANCELLED" })

            assessment_settings[:lodged_rrns].each do |rrn|
              fetch_assessment_summary(id: rrn, accepted_responses: [410])
            end
          end

          it "can change report type #{assessment_name} to NOT_FOR_ISSUE" do
            create_assessor(assessment_settings[:assessor_qualification])

            get_lodgement(assessment_settings[:xml], [201], schema_name)

            first_rrn = assessment_settings[:lodged_rrns].first
            assessment_status =
              JSON.parse(
                update_assessment_status(
                  assessment_id: first_rrn.to_s,
                  assessment_status_body: {
                    "status": "NOT_FOR_ISSUE",
                  },
                  accepted_responses: [200],
                  auth_data: {
                    scheme_ids: [scheme_id],
                  },
                ).body,
                symbolize_names: true,
              )

            expect(assessment_status[:data]).to eq({ status: "NOT_FOR_ISSUE" })

            assessment_settings[:lodged_rrns].each do |rrn|
              fetch_assessment_summary(id: rrn, accepted_responses: [410])
            end
          end
        end
      end
    end
  end
end
