describe "Integration::Rackup" do
  include RSpecRegisterApiServiceMixin

  context "when rackup has started" do
    context "when a request is made to /healthcheck" do
      let(:response) { get("/healthcheck") }

      it "return a status of 200" do
        expect(response.status).to eq(200)
      end
    end

    context "when a request is made to a non-existent page" do
      let(:response) { get("/does-not-exist") }

      it "return a status of 404" do
        expect(response.status).to eq(404)
      end

      it "return a status of Method not found" do
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[:errors][0][:title]).to eq("Method not found")
      end
    end

    context "when a request is made to /api/schemes" do
      let(:response) do
        header("Authorization", "Bearer #{get_valid_jwt(%w[scheme:list])}")
        get("/api/schemes")
      end

      it "return a status of 200" do
        expect(response.status).to eq(200)
      end
    end

    context "when an unauthenticated request is made to /api/schemes" do
      let(:response) { get("/api/schemes") }

      it "return a status of 401" do
        expect(response.status).to eq(401)
      end
    end
  end
end
