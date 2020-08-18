# frozen_string_literal: true

describe "Acceptance::AssessorStatus" do
  include RSpecRegisterApiServiceMixin

  let!(:scheme_id) { add_scheme_and_get_id }

  it "doesn't show any assessor status changes when none has happened" do
    response =
      JSON.parse(fetch_assessors_status(scheme_id).body, symbolize_names: true)

    expect(response[:data]).to eq({ assessorStatusEvents: [] })
  end
end
