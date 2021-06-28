describe UseCase::AddAssessor do
  context "given a command to add an assessor with an invalid assessor ID" do
    it "raises an invalid assessor ID exception" do
      bad_assessor_id = "this_is_bad"
      add_assessor_request =
        Boundary::AssessorRequest.new(
          body: {},
          scheme_assessor_id: bad_assessor_id,
          registered_by_id: 1,
        )
      expect {
        UseCase::AddAssessor.new.execute(add_assessor_request, "fake_token")
      }.to raise_error UseCase::AddAssessor::InvalidAssessorIdException, /#{Regexp.quote(bad_assessor_id)}/
    end
  end
end
