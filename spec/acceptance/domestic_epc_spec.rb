# frozen_string_literal: true

describe 'Acceptance::Assessor' do
  include RSpecAssessorServiceMixin

  let(:valid_epc_body) do
    {
      dateOfAssessment: '2020-01-13',
      dateOfCertificate: '2020-01-13',
      totalFloorArea: 1_000,
      typeOfAssessment: 'string',
      dwellingType: 'Top floor flat',
      addressSummary: '123 Victoria Street, London, SW1A 1BD'
    }
  end

  def certificate_without(key)
    certificate = valid_epc_body.dup
    certificate.delete(key)
    certificate
  end

  def fetch_certificate(certificate_id)
    get "api/certificates/epc/domestic/#{certificate_id}"
  end

  def migrate_certificate(certificate_id, certificate_body)
    put(
      "api/certificates/epc/domestic/#{certificate_id}",
      certificate_body.to_json
    )
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
      response =
        authenticate_and { migrate_certificate('123-456', valid_epc_body) }
      expect(response.status).to eq(200)
    end

    it 'returns the certificate that was migrated' do
      response =
        authenticate_and { migrate_certificate('123-456', valid_epc_body).body }

      migrated_certificate = JSON.parse(response)
      expected_response =
        JSON.parse(
          {
            dateOfAssessment: valid_epc_body[:dateOfAssessment],
            dateOfCertificate: valid_epc_body[:dateOfCertificate],
            totalFloorArea: valid_epc_body[:totalFloorArea],
            typeOfAssessment: valid_epc_body[:typeOfAssessment],
            dwellingType: valid_epc_body[:dwellingType],
            addressSummary: valid_epc_body[:addressSummary],
            certificateId: '123-456'
          }.to_json
        )

      expect(migrated_certificate).to eq(expected_response)
    end

    it 'rejects a certificate without an address summary' do
      response =
        authenticate_and do
          migrate_certificate('123-456', certificate_without(:addressSummary))
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a certificate with an address summary that is not a string' do
      epc_with_dodgy_address = valid_epc_body.dup
      epc_with_dodgy_address[:addressSummary] = 123_321
      response =
        authenticate_and do
          migrate_certificate('123-456', epc_with_dodgy_address)
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a certificate without a date of assessment' do
      response =
        authenticate_and do
          migrate_certificate('123-456', certificate_without(:dateOfAssessment))
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a certificate with an date of assessment that is not a date' do
      epc_with_dodge_date_of_address = valid_epc_body.dup
      epc_with_dodge_date_of_address[:dateOfAssessment] = 'horse'
      response =
        authenticate_and do
          migrate_certificate('123-456', epc_with_dodge_date_of_address)
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a certificate without a date of certificate' do
      response =
        authenticate_and do
          migrate_certificate(
            '123-456',
            certificate_without(:dateOfCertificate)
          )
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a certificate with a date of certificate that is not a date' do
      epc_with_dodge_date_of_certificate = valid_epc_body.dup
      epc_with_dodge_date_of_certificate[:dateOfCertificate] = 'horse'
      response =
        authenticate_and do
          migrate_certificate('123-456', epc_with_dodge_date_of_certificate)
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a certificate without a total floor area' do
      response =
        authenticate_and do
          migrate_certificate('123-456', certificate_without(:totalFloorArea))
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a certificate with a total floor area that is not an integer' do
      epc_with_dodgy_total_floor_area = valid_epc_body.dup
      epc_with_dodgy_total_floor_area[:totalFloorArea] = 'horse'
      response =
        authenticate_and do
          migrate_certificate('123-456', epc_with_dodgy_total_floor_area)
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a certificate without a dwelling type' do
      response =
        authenticate_and do
          migrate_certificate('123-456', certificate_without(:dwellingType))
        end
      expect(response.status).to eq(422)
    end

    it 'rejects a certificate with a dwelling type that is not a string' do
      epc_with_dodgy_dwelling_type = valid_epc_body.dup
      epc_with_dodgy_dwelling_type[:dwellingType] = 456765
      response =
        authenticate_and do
          migrate_certificate('123-456', epc_with_dodgy_dwelling_type)
        end
      expect(response.status).to eq(422)
    end
  end
end
