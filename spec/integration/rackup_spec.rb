require 'net/http'

describe 'starts server outside of ruby'  do
  def return_pid_from_lsof(port)
    lines = `lsof -i :#{port}`.split('ruby')
    first_line = lines[1].strip
    first_line.split(" ")[0]
  end 

  describe 'the server running live' do
    before(:all) do
      fork  do
        _, _ = IO.pipe
        IO.popen("rackup") 
      end 
      sleep 1
    end

    after(:all) do
      pid = return_pid_from_lsof(9292)
      `kill -9 #{pid}`
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