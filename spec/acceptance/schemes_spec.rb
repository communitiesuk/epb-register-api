describe AssessorService do
  describe 'The Schemes API' do
    context 'getting an empty list of schemes' do
      let(:response) { get '/api/schemes' }

      it 'returns status 200' do
        expect(response.status).to eq(200)
      end

      it 'returns JSON' do
        expect(response.headers['Content-Type']).to eq('application/json')
      end

      it 'includes an empty list of schemes' do
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to eq('schemes' => [])
      end
    end

    context 'posting to the schemes api' do
      response = false
      request_body = { name: 'XYMZALERO' }.to_json
      before(:each) { response = post('/api/schemes', request_body) }

      it 'returns status 201' do
        expect(response.status).to eq(201)
      end

      it 'returns json' do
        expect(response.headers['Content-Type']).to eq('application/json')
      end

      it 'is visible in the list of schemes' do
        get_response = JSON.parse((get '/api/schemes').body)
        expect(get_response['schemes'][0]['name']).to eq('XYMZALERO')
      end

      it 'cannot have the same name twice' do
        second_post_response = post '/api/schemes', request_body
        expect(second_post_response.status).to eq(400)
      end
    end
  end
end
