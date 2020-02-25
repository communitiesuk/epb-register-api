# frozen_string_literal: true

describe 'Acceptance::AssessorList' do
  include RSpecAssessorServiceMixin

  def fetch_assessors(scheme_id)
    get "/api/schemes/#{scheme_id}/assessors"
  end

  def add_scheme(name = 'test scheme')
    JSON.parse(post('/api/schemes', { name: name }.to_json).body)['schemeId']
  end

  context "when a scheme doesn't exist" do
    it 'returns status 404 for a get' do
      expect(authenticate_and { fetch_assessors(20) }.status).to eq(404)
    end

    it 'returns the error response for a get' do
      expect(authenticate_and { fetch_assessors(20) }.body).to eq(
        {
          errors: [
            { "code": 'NOT_FOUND', title: 'The requested scheme was not found' }
          ]
        }.to_json
      )
    end
  end

  context 'when a scheme has no assessors' do
    it 'returns status 200 for a get' do
      scheme_id = authenticate_and { add_scheme }

      expect(authenticate_and { fetch_assessors(scheme_id) }.status).to eq(200)
    end

    it 'returns an empty list' do
      scheme_id = authenticate_and {add_scheme}
      expected = {data: {assessors: []}}.to_json
      expect(authenticate_and { fetch_assessors(scheme_id) }.body).to eq(expected)
    end
  end
end
