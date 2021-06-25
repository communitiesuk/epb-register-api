describe "Integration::Rackup" do
  include RSpecRegisterApiServiceMixin

  context "when rackup has started" do
    context "requests to /healthcheck" do
      let(:response) { get("/healthcheck") }

      it "return a status of 200" do
        expect(response.status).to eq(200)
      end
    end

    context "requests to a non-existent page" do
      let(:response) { get("/does-not-exist") }
      let(:response) { get("/energy-certificate/:%0000-0000-0000-0000-0000") }
      let(:response) { get("/energy-certificate/:%0000-0000-0000-0000-0000") }

      it "return a status of 404" do
        expect(response.status).to eq(404)
      end

      it "return a status of Method not found" do
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[:errors][0][:title]).to eq("Method not found")
      end
    end

    context "requests to /api/schemes" do
      let(:response) do
        header("Authorization", "Bearer " + get_valid_jwt(%w[scheme:list]))
        get("/api/schemes")
      end

      it "return a status of 200" do
        expect(response.status).to eq(200)
      end
    end

    context "unauthenticated requests to /api/schemes" do
      let(:response) { get("/api/schemes") }

      it "return a status of 401" do
        expect(response.status).to eq(401)
      end
    end
  end
end
