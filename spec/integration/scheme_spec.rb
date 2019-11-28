require 'api'

describe AssessorService do
  describe 'the server having started' do
    context 'responses from /api/schemes' do
      let(:response) { get '/api/schemes' }

      it 'includes an empty scheme' do
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to eq('schemes'=>[])
      end
    end

    context 'responses from schemes after posting' do
      let(:response) do
        post '/api/schemes', '{"name": "Scheme name"}'
        get '/api/schemes'
      end

      it 'returns scheme object' do
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['schemes'].count).to eq(1)
      end
    end

    context 'when adding a scheme' do
      let(:post_request) do
        post '/api/schemes', '{"name": "XYMZALERO"}'
      end

      it 'returns a status code of 200' do
        expect(post_request.status).to eq(201)
      end

      it 'is visible in the list of schemes' do
        post_request

        get_response = get '/api/schemes'

        expect(get_response.body).to include('XYMZALERO')
      end

      it 'cannot have the same name twice' do
        post_response = false

        2.times do
          post_response = post '/api/schemes', '{"name": "XYMZALERO"}'
        end

        expect(post_response.status).to eq(400)
      end
    end
  end
end
