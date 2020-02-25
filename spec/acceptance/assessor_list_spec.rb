# frozen_string_literal: true

describe 'Acceptance::AssessorList' do
  include RSpecAssessorServiceMixin

  def fetch_assessors(scheme_id)
    get "/api/schemes/#{scheme_id}/assessors/"
  end

  context "when a scheme doesn't exist" do
    it 'returns status 404 for a get' do
      expect(
          authenticate_and { fetch_assessors(20) }.status
      ).to eq(404)
    end
  end
end
