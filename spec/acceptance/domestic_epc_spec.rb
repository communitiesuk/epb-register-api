# frozen_string_literal: true

describe 'Acceptance::Assessor' do
  include RSpecAssessorServiceMixin

  def fetch_certificate(certificate_id)
    get "api/epc/domestic/#{certificate_id}"
  end

  def migrate_certificate(certificate_id, certificate_body)
    put("api/epc/domestic/#{certificate_id}", certificate_body.to_json)
  end

  context 'when a domestic certificate doesnt exist' do
    it 'returns status 404 for a get' do
      expect(
        authenticate_and { fetch_certificate('DOESNT-EXIST') }.status
      ).to eq(404)
    end

    it 'returns an error message structure' do
      response_body =
        authenticate_and { fetch_certificate('DOESNT-EXIST') }.body
      expect(JSON.parse(response_body)).to eq(
        {
          'errors' => [
            { 'code' => 'NOT_FOUND', 'title' => 'Certificate not found' }
          ]
        }
      )
    end
  end

  context 'when migrating a domestic EPC (put)' do
    it 'returns a 200 for a valid EPC' do
      response = authenticate_and { migrate_certificate('123-456', {}) }
      expect(response.status).to eq(200)
    end
  end
end
