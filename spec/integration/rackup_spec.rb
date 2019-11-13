require 'net/http'

require 'pry'

describe 'starts server outside of ruby'  do
  describe 'the server running live' do
    $process = 0
    before(:all) do
        fork do
          process = IO.popen("rackup")
          $process = process.pid
        end
      sleep 1
    end

    after(:all) do
      `kill -9 #{$process}`
    end 

    let(:request) { Net::HTTP.new("localhost", 9292) }
 
    context "it is running" do
      it "returns status 200" do
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
end 