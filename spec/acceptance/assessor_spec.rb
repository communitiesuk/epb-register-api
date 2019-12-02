describe AssessorService do
  describe 'The Assessor API' do
    context 'When a scheme doesnt exist' do
      it 'returns status 404 for a get' do
        response = get '/api/schemes/20/assessors/SCHEME4532'
        expect(response.status).to eq(404)
      end

      it 'returns status 404 for a PUT' do
        request_body =
          {
            firstName: 'Some',
            middleNames: 'middle',
            lastName: 'Person',
            dateOfBirth: '1991-02-25'
          }
        response = put('/api/schemes/20/assessors/SCHEME4532', request_body.to_json)

        expect(response.status).to eq(404)
      end
    end

    context 'when an assessor doesnt exist' do
      let(:post_response) { post('/api/schemes', { name: 'scheme245'}.to_json) }

      it 'returns status 404' do
        schemeid = JSON.parse(post_response.body)['schemeId']
        get_response = get "/api/schemes/#{schemeid}/assessors/SCHE2354246"

        expect(get_response.status).to eq(404)
      end
    end
  end
end
