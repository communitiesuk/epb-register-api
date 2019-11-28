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
        expect(parsed_response).to eq('schemes'=>[])
      end
    end

    context 'posting to the schemes api' do
      response = false
      before(:each) do
        response = post('/api/schemes', '{"name": "XYMZALERO"}')
      end

      it 'returns status 201' do
        expect(response.status).to eq(201)
      end

      it 'is visible in the list of schemes' do
        get_response = get '/api/schemes'
        expect(get_response.body).to include('XYMZALERO')
      end

      it 'cannot have the same name twice' do
        second_post_response = post '/api/schemes', '{"name": "XYMZALERO"}'
        expect(second_post_response.status).to eq(400)
      end
    end
  end
end