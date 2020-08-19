# frozen_string_literal: true

describe "Acceptance::AssessorStatus" do
  include RSpecRegisterApiServiceMixin

  let!(:scheme_id) { add_scheme_and_get_id }

  def create_assessor(qualifications)
    add_assessor(
      scheme_id,
      "SPEC000000",
      AssessorStub.new.fetch_request_body(qualifications),
    )
  end

  it "doesn't show any assessor status changes when none has happened" do
    response =
      JSON.parse(fetch_assessors_status(scheme_id).body, symbolize_names: true)

    expect(response[:data]).to eq({ assessorStatusEvents: [] })
  end

  it "does show an assessor status change when an existing assessors status has changed" do
    create_assessor(domesticRdSap: "ACTIVE")

    created_date = Time.now
    create_assessor(domesticRdSap: "INACTIVE")

    response =
      JSON.parse(fetch_assessors_status(scheme_id).body, symbolize_names: true)

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
end
