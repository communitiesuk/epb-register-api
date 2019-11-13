require 'api'

describe AssessorService do
  context "GET to /healthcheck" do
    let(:response) { get "/healthcheck" }

    it "returns status 200 OK" do
      expect(response.status).to eq 200
    end 
  end
end