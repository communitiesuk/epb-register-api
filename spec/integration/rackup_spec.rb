require 'net/http'

describe 'starts server outside of ruby' do
  describe 'the server running live' do
    before(:all) do
      process = IO.popen('rackup -q')
      @process_id = process.pid

      sleep 2
    end

    after(:all) { Process.kill('KILL', @process_id) }

    let(:request) { Net::HTTP.new('localhost', 9_292) }

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
        req = Net::HTTP::Get.new('/api/schemes')
        response = request.request(req)
        expect(response.code).to eq('200')
      end
    end
  end
end
