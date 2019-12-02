describe AssessorService do
  describe 'The Assessor API' do
    context 'When a scheme doesnt exist' do
      let(:response) { get '/api/schemes/20/assessors/SCHEME4532' }

      it 'returns status 404' do
        expect(response.status).to eq(404)
      end
    end
  end
end
