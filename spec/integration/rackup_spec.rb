require 'net/http'

describe 'starts server outside of ruby' do
  describe 'the server running live' do
    before(:all) do
      process = IO.popen(['rackup', err: [:child, :out]])
      @process_id = process.pid

      unless process.readline.include?('port=9292')
      end
    end

    after(:all) { Process.kill('KILL', @process_id) }

    let(:request) { Net::HTTP.new('localhost', 9292) }

    context 'it is running' do
      context '/healthcheck' do
        it 'returns status 200' do
          req = Net::HTTP::Get.new('/healthcheck')
          response = request.request(req)
          expect(response.code).to eq('200')
        end
      end

      context 'non-existent page' do
        it 'returns status 404' do
          req = Net::HTTP::Get.new('/error-message')
          response = request.request(req)
          expect(response.code).to eq('404')
        end
      end

      context '/api/schemes' do
        it 'returns status 200' do
          req = Net::HTTP::Get.new '/api/schemes'
          response = authenticate_and(req) { request.request req }
          expect(response.code).to eq '200'
        end
      end

      context '/api/schemes unauthenticated' do
        it 'returns status 401' do
          req = Net::HTTP::Get.new '/api/schemes'
          response = request.request req
          expect(response.code).to eq '401'
        end
      end
    end
  end
end
