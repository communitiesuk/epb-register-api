# frozen_string_literal: true

describe 'Acceptance::Assessor' do
  include RSpecAssessorServiceMixin

  def fetch_certificate(certificate_id)
    get "api/epc/domestic/#{certificate_id}"
  end

  context 'when a domestic certificate doesnt exist' do
    it 'returns status 404 for a get' do
      expect(
          authenticate_and { fetch_certificate('DOESNTEXIST') }.status
      ).to eq(404)
    end
  end
end

