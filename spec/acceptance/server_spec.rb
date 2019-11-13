require 'api'
require 'net/http'

describe AssessorService do
  describe 'the server having started' do
    context "responses from /healthcheck" do
      let(:response) { get "/healthcheck" }

      it "returns status 200" do
        expect(response.status).to eq 200
      end
    end

    context "responses from a 404-page" do
      let(:response) { get "/error-page" }

      it "returns status 404" do
        expect(response.status).to eq(404)
      end
    end
  end
end


describe 'the server running live' do
  let(:start_server) do
    # TODO: clean up this mess. Specifically, get ~three lines of output from rackup (IO.popen), then proceed.
    fork do
      `rackup`
    end

    sleep 1
  end

  let(:request) do
    Net::HTTP.new("localhost", 9292)
  end

  context "it is running" do
    it "returns status 200" do
      start_server

      req = Net::HTTP::Get.new("/healthcheck")
      response = request.request(req)
      expect(response.code).to eq("200")
    end

    it "returns status 404" do
      req = Net::HTTP::Get.new("/error-message")
      response = request.request(req)
      expect(response.code).to eq("404")
    end
  end
end