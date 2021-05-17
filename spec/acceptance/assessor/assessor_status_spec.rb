# frozen_string_literal: true

describe "Acceptance::AssessorStatus" do
  include RSpecRegisterApiServiceMixin
  require "pry"

  let!(:test_scheme_id) { add_scheme_and_get_id }
  let!(:test_scheme_id2) { add_scheme_and_get_id(name = "test_two") }

  def create_assessor(scheme_id = test_scheme_id, assessor_id = "SPEC000000", qualifications)
    add_assessor(
      scheme_id,
      assessor_id,
      AssessorStub.new.fetch_request_body(qualifications),
    )
  end

  it "doesn't show any assessor status changes when none has happened" do
    response =
      JSON.parse(
        fetch_assessors_status(test_scheme_id, Date.today.to_s).body,
        symbolize_names: true,
      )

    expect(response[:data]).to eq({ assessorStatusEvents: [] })
  end

  it "does show an assessor status change when an existing assessors status has changed" do
    create_assessor(domesticRdSap: "ACTIVE")
    create_assessor(domesticRdSap: "INACTIVE")

    response =
      JSON.parse(
        fetch_assessors_status(test_scheme_id, Date.today.to_s).body,
        symbolize_names: true,
      )

    expect(response[:data]).to eq(
      assessorStatusEvents: [
        {
          firstName: "Someone",
          middleNames: nil,
          lastName: "Person",
          schemeAssessorId: "SPEC000000",
          dateOfBirth: "1991-02-25",
          qualificationChange: {
            qualificationType: "domestic_rd_sap",
            previousStatus: "ACTIVE",
            newStatus: "INACTIVE",
          },
        },
      ],
    )
  end

  it "doesn't show an assessor status change done on a different date" do
    create_assessor(domesticRdSap: "ACTIVE")
    create_assessor(domesticRdSap: "INACTIVE")

    response =
      JSON.parse(
        fetch_assessors_status(test_scheme_id, Date.tomorrow.to_s).body,
        symbolize_names: true,
      )

    expect(response[:data]).to eq(assessorStatusEvents: [])
  end

  it "stores the auth client id successfully" do
    create_assessor(domesticRdSap: "ACTIVE")
    create_assessor(domesticRdSap: "INACTIVE")

    result =
      ActiveRecord::Base.connection.exec_query(
        "SELECT auth_client_id FROM assessors_status_events",
      )

    expect(result.entries.first["auth_client_id"]).to eq("test-subject")
  end

  it "will give an error if date param is empty" do
    response =
      JSON.parse(
        fetch_assessors_status(test_scheme_id, "", [400]).body,
        symbolize_names: true,
      )

    expect(response).to eq(
      { errors: [{ code: "INVALID_REQUEST", title: "invalid date" }] },
    )
  end

  context "when a scheme requests a list of assessors whose statuses have been updated" do
    let(:response) do
      JSON.parse(
        fetch_assessors_updated_status(test_scheme_id, Date.today.to_s).body,
        symbolize_names: true,
      )
    end

    it "should return only assessors registered to other schemes who might also be registered to this scheme" do
      create_assessor(test_scheme_id, "SPEC000004", firstName: "Jane", lastName: "Doe", domesticRdSap: "ACTIVE")
      create_assessor(test_scheme_id2, "SPEC000001", firstName: "Jane", lastName: "Doe", domesticRdSap: "ACTIVE")
      create_assessor(test_scheme_id2, "SPEC000001", firstName: "Jane", lastName: "Doe", domesticRdSap: "INACTIVE")

      expect(response[:data]).to eq(
        assessorStatusEvents: [
          {
            firstName: "Jane",
            lastName: "Doe",
            middleNames: nil,
            schemeAssessorId: "SPEC000001",
            dateOfBirth: "1991-02-25",
            qualificationChange:
                     { qualificationType: "domestic_rd_sap",
                       previousStatus: "ACTIVE",
                       newStatus: "INACTIVE" },
          },
        ],
      )
    end
    it "does not return an assessor with the same name but different date of birth" do
      create_assessor(test_scheme_id, "SPEC000001", firstName: "Jane", lastName: "Doe", domesticRdSap: "ACTIVE")
      create_assessor(test_scheme_id2, "SPEC000002", firstName: "Jane", lastName: "Doe", domesticRdSap: "ACTIVE", dateOfBirth: "1976-02-25")
      create_assessor(test_scheme_id2, "SPEC000002", firstName: "Jane", lastName: "Doe", domesticRdSap: "INACTIVE", dateOfBirth: "1976-02-25")

      expect(response[:data]).to eq(assessorStatusEvents: [])
    end

    it "returns assessors with the same date of birth and last name but a different first name" do
      create_assessor(test_scheme_id, "SPEC000001", firstName: "Jane", lastName: "Doe", domesticRdSap: "ACTIVE")
      create_assessor(test_scheme_id2, "SPEC000003", firstName: "Jim", lastName: "Doe", domesticRdSap: "ACTIVE")
      create_assessor(test_scheme_id2, "SPEC000003", firstName: "Jim", lastName: "Doe", domesticRdSap: "INACTIVE")

      expect(response[:data]).to eq(
        assessorStatusEvents: [
          {
            firstName: "Jim",
            lastName: "Doe",
            middleNames: nil,
            schemeAssessorId: "SPEC000003",
            dateOfBirth: "1991-02-25",
            qualificationChange:
                    { qualificationType: "domestic_rd_sap",
                      previousStatus: "ACTIVE",
                      newStatus: "INACTIVE" },
          },
        ],
      )
    end

    it "does not return assessors who have the same date of birth but different last names" do
      create_assessor(test_scheme_id, "SPEC000001", firstName: "Jane", lastName: "Doe", domesticRdSap: "ACTIVE")
      create_assessor(test_scheme_id2, "SPEC000003", firstName: "Jane", lastName: "Done", domesticRdSap: "ACTIVE")
      create_assessor(test_scheme_id2, "SPEC000003", firstName: "Jane", lastName: "Done", domesticRdSap: "INACTIVE")

      expect(response[:data]).to eq(assessorStatusEvents: [])
    end

    it "does not return assessors who have been updated by the scheme making the request" do
      create_assessor(test_scheme_id, "SPEC000001", firstName: "Jane", lastName: "Doe", domesticRdSap: "ACTIVE")
      create_assessor(test_scheme_id, "SPEC000001", firstName: "Jane", lastName: "Doe", domesticRdSap: "INACTIVE")

      expect(response[:data]).to eq(assessorStatusEvents: [])
    end
  end
end
