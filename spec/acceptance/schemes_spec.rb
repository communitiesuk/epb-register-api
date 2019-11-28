describe AssessorService do
  describe 'The Schemes API' do
    context 'responses from get /api/schemes' do
      let(:response) { get '/api/schemes' }

      it 'returns status 200' do
        expect(response.status).to eq(200)
      end

      it 'returns JSON' do
        expect(response.headers['Content-Type']).to eq('application/json')
      end
    end

    context 'responses from post /api/schemes' do
      let(:response) { post '/api/schemes', '{"name": "Scheme name"}' }

      it 'returns status 200' do
        expect(response.status).to eq(201)
      end
    end
  end
end