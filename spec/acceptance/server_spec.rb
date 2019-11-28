require 'api'

describe AssessorService do
  describe 'the server having started' do
    context 'responses from /healthcheck' do
      let(:response) { get '/healthcheck' }

      it 'returns status 200' do
        expect(response.status).to eq(200)
      end
    end

    context 'responses from a 404-page' do
      let(:response) { get '/error-page' }

      it 'returns status 404' do
        expect(response.status).to eq(404)
      end
    end

    context 'responses from get /schemes' do
      let(:response) { get '/schemes' }

      it 'returns status 200' do
        expect(response.status).to eq(200)
      end
    end

    context 'responses from post /schemes' do
      let(:response) { post '/schemes', '{"name": "Scheme name"}' }

      it 'returns status 200' do
        expect(response.status).to eq(200)
      end
    end

    context 'responses from a 404-page' do
      let(:response) { get '/error-page' }

      it 'returns status 404' do
        expect(response.status).to eq(404)
      end
    end

    context 'responses to pre-flight request' do
      let(:response) { options '/schemes'}
      it 'returns 200' do
        expect(response.status).to eq(200)
      end

      it 'allows headers for access control' do
        headers = response.headers['Access-Control-Allow-Headers'].split(/[,\s]+/)
        expect(headers).to contain_exactly('Content-Type', 'Cache-Control', 'Accept')
      end
    end
  end
end
