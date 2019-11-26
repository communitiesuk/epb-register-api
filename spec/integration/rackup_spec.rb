require 'net/http'
require 'pry'

describe 'starts server outside of ruby'  do
  describe 'the server running live' do
    before(:all) do
      process_id = IO.popen('rackup -q')
      @process_id = process_id.pid
      sleep 1
    end

    after(:all) do
      Process.kill('KILL', @process_id)
    end

    let(:request) { Net::HTTP.new('localhost', 9292) }

    context 'it is running' do
      it 'returns status 200' do
        req = Net::HTTP::Get.new('/healthcheck')
        response = request.request(req)
        expect(response.code).to eq('200')
      end

      it 'returns status 404' do
        req = Net::HTTP::Get.new('/error-message')
        response = request.request(req)
        expect(response.code).to eq('404')
      end
    end

    context 'it is running' do
      it 'returns status 200' do
        req = Net::HTTP::Get.new('/schemes')
        response = request.request(req)
        expect(response.code).to eq('200')
      end
    end
    
  end
end
