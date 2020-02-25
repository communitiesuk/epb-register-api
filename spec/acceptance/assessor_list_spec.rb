# frozen_string_literal: true

describe 'Acceptance::AssessorList' do
  include RSpecAssessorServiceMixin

  def fetch_assessors(scheme_id)
    get "/api/schemes/#{scheme_id}/assessors"
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
end
