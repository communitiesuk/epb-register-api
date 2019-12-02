describe AssessorService do
  describe 'The Assessor API' do
    context 'When a scheme doesnt exist' do
      let(:response) { get '/api/schemes/20/assessors/SCHEME4532' }

      it 'returns status 404' do
        expect(response.status).to eq(404)
      end
    end

    context 'when an assessor doesnt exist' do
      let (:post_response) { post('/api/schemes', { name: 'scheme245'}.to_json) }

      it 'returns status 404' do
        schemeid = JSON.parse(post_response.body)['schemeId']
        get_response = get "/api/schemes/#{schemeid}/assessors/SCHE2354246"

        expect(get_response.status).to eq(404)
      end
    end
  end
end
