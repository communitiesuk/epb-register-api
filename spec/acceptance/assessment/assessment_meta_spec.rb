describe "Acceptance::AssessmentMeta" do
  include RSpecRegisterApiServiceMixin

  it "returns a 200 when calling the meta data end point" do
    fetch_assessment_meta_data("0000-0000-0000-0000-0001", [200], true, %w[assessmentmetadata:fetch])
  end

  it "returns a 401 when calling the meta data end point without any data" do
    fetch_assessment_meta_data("0000-0000-0000-0000-0000", [401], false, %w[assessment:fetch])
  end

  it "rejects a request with the wrong scopes" do
    fetch_assessment_meta_data("0000-0000-0000-0000-0001", [403], true, {}, %w[wrong:scope])
  end
end
