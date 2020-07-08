describe "Acceptance::Responses" do
  include RSpecRegisterApiServiceMixin

  context "responses from /healthcheck" do
    let(:response) { get "/healthcheck" }

    it "returns status 200" do
      expect(response.status).to eq(200)
    end
  end

  context "responses from a 404-page" do
    let(:response) { get "/does-not-exist" }

    it "returns status 404" do
      expect(response.status).to eq(404)
    end
  end

  context "responses to pre-flight request" do
    let(:response) { options "/api/schemes" }

    it "returns 200" do
      expect(response.status).to eq(200)
    end

    it "allows headers for access control" do
      headers = response.headers["Access-Control-Allow-Headers"].split(/[,\s]+/)
      expect(headers).to contain_exactly(
        "Content-Type",
        "Cache-Control",
        "Accept",
      )
    end

    it "allows clients to use all methods used" do
      headers = response.headers["Access-Control-Allow-Methods"].split(/[,\s]+/)
      expect(headers).to contain_exactly(
        "HEAD",
        "GET",
        "PUT",
        "POST",
        "OPTIONS",
        "DELETE",
      )
    end
  end
end
