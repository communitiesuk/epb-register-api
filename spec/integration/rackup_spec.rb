require 'net/http'

describe 'Integration::Rackup' do
  before(:all) do
    process = IO.popen(['rackup', '-p 9191', err: %i[child out]])
    @process_id = process.pid

    unless process.readline.include?('port=9191')
    end
  end

  after(:all) { Process.kill('KILL', @process_id) }

  let(:request) { Net::HTTP.new('127.0.0.1', 9_191) }

  context 'when rackup has started' do
    context 'requests to /healthcheck' do
      it 'return a status of 200' do
        req = Net::HTTP::Get.new('/healthcheck')
        response = request.request(req)
        expect(response.code).to eq('200')
      end
    end

    context 'requests to a non-existent page' do
      it 'return a status of 404' do
        req = Net::HTTP::Get.new('/does-not-exist')
        response = request.request(req)
        expect(response.code).to eq('404')
      end
    end

    context 'requests to /api/schemes' do
      it 'return a status of 200' do
        req = Net::HTTP::Get.new '/api/schemes'
        response =
          authenticate_and(req, %w[scheme:list]) { request.request req }
        expect(response.code).to eq '200'
      end
    end

    context 'unauthenticated requests to /api/schemes' do
      it 'return a status of 401' do
        req = Net::HTTP::Get.new '/api/schemes'
        response = request.request req
        expect(response.code).to eq '401'
      end
    end
  end
end
