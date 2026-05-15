# frozen_string_literal: true

shared_examples "when checking an endpoint requires bearer token access" do |end_point:, scopes:|
  context "when making an invalid request to #{end_point}" do
    let(:path) do
      "/api/#{end_point}"
    end

    it "rejects a request without authentication" do
      response = assertive_get(path, scopes:, accepted_responses: [401], should_authenticate: false)
      expect(response.status).to eq(401)
    end

    it "returns a 403 when the right scopes are not present" do
      response = assertive_get(path, scopes: %w[wrong:scope], accepted_responses: [403])
      expect(response.status).to eq(403)
    end
  end
end
