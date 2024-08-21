shared_examples "address_search_by_id_error" do |argument:, status_code:|
  it "returns status {status_code}" do
    expect(address_search_by_id(argument, accepted_responses: [status_code]).status).to eq status_code
  end
end

shared_examples "scheme_list" do |argument:, status_code:|
  it "returns status #{status_code}" do
    expect(address_search_by_id(argument, accepted_responses: [status_code]).status).to eq status_code
  end
end

shared_examples "assertive_get" do |path:, status_code:, scopes:, assertion: "", should_authenticate: true|
  it "returns status #{status_code} #{assertion}" do
    expect(assertive_get(path, accepted_responses: [status_code], scopes:, should_authenticate:).status).to eq status_code
  end
end

shared_examples "opt_out_assessment" do |rrn:, status_code:, opt_out:|
  it "returns status #{status_code}" do
    expect(opt_out_assessment(assessment_id: rrn, opt_out:, accepted_responses: [status_code]).status).to eq status_code
  end
end
