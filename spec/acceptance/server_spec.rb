describe "Acceptance::Responses" do
  include RSpecRegisterApiServiceMixin

  context "when getting a response from /healthcheck" do
    let(:response) { get "/healthcheck" }

    it "returns status 200" do
      expect(response.status).to eq(200)
    end
  end

  context "when getting a responses from a page that does not exist" do
    let(:response) { get "/does-not-exist" }

    it "returns status 404" do
      expect(response.status).to eq(404)
    end
  end

  context "when getting responses to pre-flight request" do
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
        "Authorization",
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

    it "has no Access-Control-Allow-Origin header" do
      expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
    end

    context "and API docs URL is set in the environment" do
      let(:docs_url) { "http://epb-api-docs/" }

      before do
        allow(ENV).to receive(:[])
        allow(ENV).to receive(:[]).with("EPB_API_DOCS_URL").and_return(docs_url)
      end

      it "has an Access-Control-Allow-Origin header set to the docs URL" do
        expect(response.headers["Access-Control-Allow-Origin"]).to eq docs_url
      end
    end
  end

  context "when sending a response when API docs URL is not set in environment" do
    let(:response) { options "/api/schemes" }

    it "has no Access-Control-Allow-Origin header" do
      expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
    end
  end

  context "when sending a response when API docs URL is set in environment" do
    let(:docs_url) { "http://epb-api-docs/" }
    let(:response) { options "/api/schemes" }

    before do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with("EPB_API_DOCS_URL").and_return(docs_url)
    end

    it "has an Access-Control-Allow-Origin header set to the docs URL" do
      expect(response.headers["Access-Control-Allow-Origin"]).to eq docs_url
    end

    it "has a Vary header set to Origin" do
      expect(response.headers["Vary"]).to eq "Origin"
    end

    it "has an Access-Control-Allow-Credentials header set to true" do
      expect(response.headers["Access-Control-Allow-Credentials"]).to eq "true"
    end
  end
end
