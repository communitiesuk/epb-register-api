describe UseCase::AddAssessor do
  subject(:use_case) do
    described_class.new(
      schemes_gateway: instance_double(Gateway::SchemesGateway),
      assessors_gateway: instance_double(Gateway::AssessorsGateway),
      assessors_status_events_gateway: instance_double(Gateway::AssessorsStatusEventsGateway),
      event_broadcaster: instance_double(Events::Broadcaster),
    )
  end

  it "raises an exeption for an invalid assessor ID" do
    bad_assessor_id = "this_is_bad"
    add_assessor_request =
      Boundary::AssessorRequest.new(
        body: {},
        scheme_assessor_id: bad_assessor_id,
        registered_by_id: 1,
      )
    expect {
      use_case.execute(add_assessor_request, "fake_token")
    }.to raise_error UseCase::AddAssessor::InvalidAssessorIdException,
                     /#{Regexp.quote(bad_assessor_id)}/
  end
end
