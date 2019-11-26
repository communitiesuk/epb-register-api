require 'api'

describe AssessorService do
  describe 'the server having started' do
    context 'responses from /schemes' do
      let(:response) { get '/schemes' }

      it 'includes an empty scheme' do
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to eq({"schemes"=>"[]"})
      end
    end
  end 
end 