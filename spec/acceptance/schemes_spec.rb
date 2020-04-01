describe 'Acceptance::Schemes' do
  include RSpecAssessorServiceMixin

  context 'getting a list of schemes security' do
    it 'returns status 401 with no authentication' do
      schemes_list([401], false)
    end
    it 'returns status 403 without the right scope' do
      schemes_list([403], true, {}, %w[wrong:scope])
    end
  end

  context 'getting an empty list of schemes' do
    it 'returns status 200' do
      schemes_list([200], true, {})
    end

    it 'returns JSON' do
      expect(schemes_list.headers['Content-Type']).to eq('application/json')
    end

    it 'includes an empty list of schemes' do
      parsed_response = JSON.parse(schemes_list.body, symbolize_names: true)
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
      response = schemes_list
      get_response = JSON.parse(response.body)
      expect(get_response['data']['schemes'][0]['name']).to eq('XYMZALERO')
    end

    it 'cannot have the same name twice' do
      add_scheme('XYMZALERO', [201])
      add_scheme('XYMZALERO', [400])
    end
  end
end
