# frozen_string_literal: true

describe "Acceptance::AssessorStatus" do
  include RSpecRegisterApiServiceMixin

  let!(:test_scheme_id) { add_scheme_and_get_id }
  let!(:test_scheme_id2) { add_scheme_and_get_id("test_two") }

  def create_assessor(
    scheme_id: test_scheme_id,
    assessor_id: "SPEC000000",
    **other_args
  )
    add_assessor(
      scheme_id,
      assessor_id,
      AssessorStub.new.fetch_request_body(**other_args),
    )
  end

  context "when a scheme requests a list of assessors whose statuses have been updated" do
    let(:response) do
      JSON.parse(
        fetch_assessors_updated_status(test_scheme_id, Date.today.to_s).body,
        symbolize_names: true,
      )
    end

    it "will give an error if date param is empty" do
      response =
        JSON.parse(
          fetch_assessors_updated_status(test_scheme_id, "", [400]).body,
          symbolize_names: true,
        )

      expect(response).to eq(
        { errors: [{ code: "INVALID_REQUEST", title: "invalid date" }] },
      )
    end

    it "doesn't show any assessor status changes when none has happened" do
      expect(response[:data]).to eq({ assessorStatusEvents: [] })
    end

    it "doesn't show an assessor status change done on a different date" do
      create_assessor(
        first_name: "Jane",
        last_name: "Doe",
        domestic_rd_sap: "ACTIVE",
        scheme_id: test_scheme_id,
        assessor_id: "SPEC000004",
      )
      create_assessor(
        first_name: "Jane",
        last_name: "Doe",
        domestic_rd_sap: "ACTIVE",
        scheme_id: test_scheme_id2,
        assessor_id: "SPEC000001",
      )
      create_assessor(
        first_name: "Jane",
        last_name: "Doe",
        domestic_rd_sap: "INACTIVE",
        scheme_id: test_scheme_id2,
        assessor_id: "SPEC000001",
      )

      response =
        JSON.parse(
          fetch_assessors_updated_status(test_scheme_id, Date.tomorrow.to_s)
            .body,
          symbolize_names: true,
        )

      expect(response[:data]).to eq(assessorStatusEvents: [])
    end

    it "returns only assessors registered to other schemes who might also be registered to this scheme" do
      create_assessor(
        first_name: "Jane",
        last_name: "Doe",
        domestic_rd_sap: "ACTIVE",
        scheme_id: test_scheme_id,
        assessor_id: "SPEC000004",
      )
      create_assessor(
        first_name: "Jane",
        last_name: "Doe",
        domestic_rd_sap: "ACTIVE",
        scheme_id: test_scheme_id2,
        assessor_id: "SPEC000001",
      )
      create_assessor(
        first_name: "Jane",
        last_name: "Doe",
        domestic_rd_sap: "INACTIVE",
        scheme_id: test_scheme_id2,
        assessor_id: "SPEC000001",
      )

      expect(response[:data]).to eq(
        assessorStatusEvents: [
          {
            firstName: "Jane",
            lastName: "Doe",
            middleNames: nil,
            schemeAssessorId: "SPEC000001",
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

    it "does not return an assessor with the same name but different date of birth" do
      create_assessor(
        scheme_id: test_scheme_id,
        assessor_id: "SPEC000001",
        first_name: "Jane",
        last_name: "Doe",
        domestic_rd_sap: "ACTIVE",
      )
      create_assessor(
        scheme_id: test_scheme_id2,
        assessor_id: "SPEC000002",
        first_name: "Jane",
        last_name: "Doe",
        domestic_rd_sap: "ACTIVE",
        date_of_birth: "1976-02-25",
      )
      create_assessor(
        scheme_id: test_scheme_id2,
        assessor_id: "SPEC000002",
        first_name: "Jane",
        last_name: "Doe",
        domestic_rd_sap: "INACTIVE",
        date_of_birth: "1976-02-25",
      )

      expect(response[:data]).to eq(assessorStatusEvents: [])
    end

    it "returns assessors with the same date of birth and last name but a different first name" do
      create_assessor(
        scheme_id: test_scheme_id,
        assessor_id: "SPEC000001",
        first_name: "Jane",
        last_name: "Doe",
        domestic_rd_sap: "ACTIVE",
      )
      create_assessor(
        scheme_id: test_scheme_id2,
        assessor_id: "SPEC000003",
        first_name: "Ash",
        last_name: "Doe",
        domestic_rd_sap: "ACTIVE",
      )
      create_assessor(
        scheme_id: test_scheme_id2,
        assessor_id: "SPEC000003",
        first_name: "Ash",
        last_name: "Doe",
        domestic_rd_sap: "INACTIVE",
      )

      expect(response[:data]).to eq(
        assessorStatusEvents: [
          {
            firstName: "Ash",
            lastName: "Doe",
            middleNames: nil,
            schemeAssessorId: "SPEC000003",
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

    it "does not return assessors who have the same date of birth but different last names" do
      create_assessor(
        scheme_id: test_scheme_id,
        assessor_id: "SPEC000001",
        first_name: "Jane",
        last_name: "Doe",
        domestic_rd_sap: "ACTIVE",
      )
      create_assessor(
        scheme_id: test_scheme_id2,
        assessor_id: "SPEC000003",
        first_name: "Jane",
        last_name: "Done",
        domestic_rd_sap: "ACTIVE",
      )
      create_assessor(
        scheme_id: test_scheme_id2,
        assessor_id: "SPEC000003",
        first_name: "Jane",
        last_name: "Done",
        domestic_rd_sap: "INACTIVE",
      )

      expect(response[:data]).to eq(assessorStatusEvents: [])
    end

    it "does not return assessors who have been updated by the scheme making the request" do
      create_assessor(
        scheme_id: test_scheme_id,
        assessor_id: "SPEC000001",
        first_name: "Jane",
        last_name: "Doe",
        domestic_rd_sap: "ACTIVE",
      )
      create_assessor(
        scheme_id: test_scheme_id,
        assessor_id: "SPEC000001",
        first_name: "Jane",
        last_name: "Doe",
        domestic_rd_sap: "INACTIVE",
      )

      expect(response[:data]).to eq(assessorStatusEvents: [])
    end
  end
end
