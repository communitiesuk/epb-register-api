# frozen_string_literal: true

describe 'Acceptance::Assessor' do
  include RSpecAssessorServiceMixin

  let(:valid_epc_body) do
    {
      dateOfAssessment: "2020-01-13",
      dateOfCertificate: "2020-01-13",
      totalFloorArea: "string",
      typeOfAssessment: "string",
      dwellingType: "string",
      addressSummary: "123 Victoria Street, London, SW1A 1BD"
    }
  end

  def fetch_certificate(certificate_id)
    get "api/certificates/epc/domestic/#{certificate_id}"
  end

  def migrate_certificate(certificate_id, certificate_body)
    put("api/certificates/epc/domestic/#{certificate_id}", certificate_body.to_json)
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
      response = authenticate_and do
        migrate_certificate('123-456', valid_epc_body)
      end
      expect(response.status).to eq(200)
    end

    it 'returns the certificate that was migrated' do
      response = authenticate_and do
        migrate_certificate('123-456', valid_epc_body).body
      end

      migrated_certificate = JSON.parse(response)
      expected_response =
          JSON.parse({
              dateOfAssessment: valid_epc_body[:dateOfAssessment],
              dateOfCertificate: valid_epc_body[:dateOfCertificate],
              totalFloorArea: valid_epc_body[:totalFloorArea],
              typeOfAssessment: valid_epc_body[:typeOfAssessment],
              dwellingType: valid_epc_body[:dwellingType],
              addressSummary: valid_epc_body[:addressSummary],
              certificateId: '123-456'
          }.to_json)

      expect(migrated_certificate).to eq(expected_response)
    end

    it 'rejects a certificate without an address summary' do
      epc_with_dodgy_address = valid_epc_body.dup
      epc_with_dodgy_address.delete(:addressSummary)
      response = authenticate_and { migrate_certificate('123-456', epc_with_dodgy_address)}
      expect(response.status).to eq(422)
    end

    it 'rejects a certificate with an address summary that is not a string' do
      epc_with_dodgy_address = valid_epc_body.dup
      epc_with_dodgy_address[:addressSummary] = 123321
      response = authenticate_and { migrate_certificate('123-456', epc_with_dodgy_address)}
      expect(response.status).to eq(422)
    end

  end
end
