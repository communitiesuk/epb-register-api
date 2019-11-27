require 'api'

describe AssessorService do
  describe 'the server having started' do
    context 'responses from /schemes' do
      let(:response) { get '/schemes' }

      it 'includes an empty scheme' do
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to eq({"schemes"=>[]})
      end
    end

    context 'responses from schemes after posting' do
      let(:response) do
        post '/schemes', :schemes => {:name => "Scheme name"}
        get '/schemes'
      end

      it 'returns scheme object' do
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["schemes"].count).to eq(1)
      end
    end

    context 'responses from schemes after posting' do
      let(:response) do
        post '/schemes', :schemes => {:name => "Scheme name"}
      end

      it 'returns a status code of 200' do
        expect(response.status).to eq(200)
      end
    end
  end
end
