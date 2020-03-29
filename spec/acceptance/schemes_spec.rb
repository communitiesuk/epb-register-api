describe 'Acceptance::Schemes' do
  include RSpecAssessorServiceMixin

  context 'getting an empty list of schemes without authentication' do
    let(:response) { get '/api/schemes' }

    it 'returns status 401' do
      expect(response.status).to eq 401
    end
  end

  context 'getting an empty list of schemes' do
    let(:response) { authenticate_and { get '/api/schemes' } }

    it 'returns status 200' do
      expect(response.status).to eq(200)
    end

    it 'returns JSON' do
      expect(response.headers['Content-Type']).to eq('application/json')
    end

    it 'includes an empty list of schemes' do
      parsed_response = JSON.parse(response.body, symbolize_names: true)
      expect(parsed_response).to eq({ data: { schemes: [] }, meta: {} })
    end
  end

  context 'posting to the schemes api without authentication' do
    it 'returns status 401' do
      add_scheme('TEST', [401], false)
    end
  end

  context 'posting to the schemes api' do
    it 'returns status 201' do
      add_scheme('XYMZALERO', [201])
    end

    it 'returns json' do
      response = add_scheme('XYMZALERO', [201])
      expect(response.headers['Content-Type']).to eq('application/json')
    end

    it 'is visible in the list of schemes' do
      add_scheme('XYMZALERO')
      response = authenticate_and { get '/api/schemes' }
      get_response = JSON.parse(response.body)
      expect(get_response['data']['schemes'][0]['name']).to eq('XYMZALERO')
    end

    it 'cannot have the same name twice' do
      add_scheme('XYMZALERO', [201])
      add_scheme('XYMZALERO', [400])
    end
  end
end
