describe Controller::FindAssessorController do
  context 'when findassessor receives GET request' do
    it 'returns an object' do
      response = authenticate_and { get '/api/findassessor/E2+0SZ' }

      expect(response.body).to eq('1')
    end
  end
end
