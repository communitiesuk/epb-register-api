# frozen_string_literal: true

describe AssessorService do
  describe 'The Assessor API' do
    let(:valid_assessor_request_body) do
      {
        firstName: 'Someone',
        middleNames: 'muddle',
        lastName: 'Person',
        dateOfBirth: '1991-02-25'
      }
    end

    let(:valid_assessor_with_contact_request_body) do
      {
        firstName: 'Some',
        middleNames: 'middle',
        lastName: 'Person',
        dateOfBirth: '1991-02-25',
        contactDetails: {
          telephoneNumber: '010199991010101', email: 'person@person.com'
        }
      }
    end

    def fetch_assessor(scheme_id, assessor_id)
      get "/api/schemes/#{scheme_id}/assessors/#{assessor_id}"
    end

    def add_assessor(scheme_id, assessor_id, body)
      put("/api/schemes/#{scheme_id}/assessors/#{assessor_id}", body.to_json)
    end

    def add_scheme(name = 'test scheme')
      JSON.parse(post('/api/schemes', { name: name }.to_json).body)['schemeId']
    end

    def assessor_without_key(missing, request_body)
      assessor = request_body.dup
      assessor.delete(missing)
      assessor
    end

    context 'When a scheme doesnt exist' do
      it 'returns status 404 for a get' do
        expect(fetch_assessor(20, 'SCHEME4233').status).to eq(404)
      end

      it 'returns status 404 for a PUT' do
        expect(
          add_assessor(20, 'SCHEME4532', valid_assessor_request_body).status
        ).to eq(404)
      end
    end

    context 'when an assessor doesnt exist' do
      it 'returns status 404' do
        scheme_id = add_scheme
        expect(fetch_assessor(scheme_id, 'SCHE2354246').status).to eq(404)
      end
    end

    context 'when getting an assessor on the wrong scheme' do
      it 'returns status 404' do
        scheme_id = add_scheme
        second_scheme_id = add_scheme('second scheme')
        add_assessor(
          second_scheme_id,
          'SCHE987654',
          valid_assessor_request_body
        )

        expect(fetch_assessor(scheme_id, 'SCHE987654').status).to eq(404)
      end
    end

    context 'when getting an assessor' do
      context 'and the assessor exists on the correct scheme' do
        it 'returns status 200 for a get' do
          scheme_id = add_scheme
          add_assessor(scheme_id, 'SCHEME4233', valid_assessor_request_body)
          expect(fetch_assessor(scheme_id, 'SCHEME4233').status).to eq(200)
        end

        it 'returns json' do
          scheme_id = add_scheme
          add_assessor(scheme_id, 'SCHEME4233', valid_assessor_request_body)
          expect(
            fetch_assessor(scheme_id, 'SCHEME4233').headers['Content-type']
          ).to eq('application/json')
        end

        it 'returns the correct details for the assessor' do
          scheme_id = add_scheme
          add_assessor(scheme_id, 'SCHEME4233', valid_assessor_request_body)
          expected_response =
            JSON.parse(
              {
                registeredBy: { schemeId: scheme_id, name: 'test scheme' },
                schemeAssessorId: 'SCHEME4233',
                firstName: valid_assessor_request_body[:firstName],
                middleNames: valid_assessor_request_body[:middleNames],
                lastName: valid_assessor_request_body[:lastName],
                dateOfBirth: valid_assessor_request_body[:dateOfBirth],
                contactDetails: { telephoneNumber: '', email: '' }
              }.to_json
            )
          response = JSON.parse(fetch_assessor(scheme_id, 'SCHEME4233').body)
          expect(response).to eq(expected_response)
        end
      end
    end

    context 'when creating an assessor' do
      context 'which is valid with all fields' do
        it 'returns 201 created' do
          scheme_id = add_scheme
          assessor_response =
            add_assessor(scheme_id, 'SCHE55443', valid_assessor_request_body)

          expect(assessor_response.status).to eq(201)
        end

        it 'returns JSON' do
          scheme_id = add_scheme
          assessor_response =
            add_assessor(scheme_id, 'SCHE55443', valid_assessor_request_body)

          expect(assessor_response.headers['Content-type']).to eq(
            'application/json'
          )
        end

        it 'returns assessor details with scheme details' do
          scheme_id = add_scheme
          assessor_response =
            JSON.parse(
              add_assessor(scheme_id, 'SCHE55443', valid_assessor_request_body)
                .body
            )

          expected_response =
            JSON.parse(
              {
                registeredBy: { schemeId: scheme_id.to_s, name: 'test scheme' },
                schemeAssessorId: 'SCHE55443',
                firstName: valid_assessor_request_body[:firstName],
                middleNames: valid_assessor_request_body[:middleNames],
                lastName: valid_assessor_request_body[:lastName],
                dateOfBirth: valid_assessor_request_body[:dateOfBirth]
              }.to_json
            )

          expect(assessor_response).to eq(expected_response)
        end
      end

      context 'which is valid with optional fields missing' do
        it 'returns 201 created' do
          scheme_id = add_scheme
          assessor_response =
            add_assessor(
              scheme_id,
              'SCHE55443',
              assessor_without_key(:middleNames, valid_assessor_request_body)
            )

          expect(assessor_response.status).to eq(201)
        end

        it 'returns assessor details with scheme details' do
          scheme_id = add_scheme
          assessor_response =
            JSON.parse(
              add_assessor(
                scheme_id,
                'SCHE55443',
                assessor_without_key(:middleNames, valid_assessor_request_body)
              )
                .body
            )

          expected_response =
            JSON.parse(
              {
                registeredBy: { schemeId: scheme_id.to_s, name: 'test scheme' },
                schemeAssessorId: 'SCHE55443',
                firstName:
                  assessor_without_key(
                    :middleNames,
                    valid_assessor_request_body
                  )[
                    :firstName
                  ],
                lastName:
                  assessor_without_key(
                    :middleNames,
                    valid_assessor_request_body
                  )[
                    :lastName
                  ],
                dateOfBirth:
                  assessor_without_key(
                    :middleNames,
                    valid_assessor_request_body
                  )[
                    :dateOfBirth
                  ]
              }.to_json
            )

          expect(assessor_response).to eq(expected_response)
        end
      end

      context 'which is invalid' do
        it 'rejects anything that isnt JSON' do
          scheme_id = add_scheme
          assessor_response =
            put(
              "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
              '>>>this is not json<<<'
            )

          expect(assessor_response.status).to eq(400)
        end

        it 'rejects an empty request body' do
          scheme_id = add_scheme
          assessor_response =
            put("/api/schemes/#{scheme_id}/assessors/thebrokenassessor")

          expect(assessor_response.status).to eq(400)
        end

        it 'rejects requests without firstname' do
          scheme_id = add_scheme
          assessor_response =
            put(
              "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
              assessor_without_key(:firstName, valid_assessor_request_body).to_json
            )

          expect(assessor_response.status).to eq(422)
        end

        it 'rejects requests without last name' do
          scheme_id = add_scheme
          assessor_response =
            put(
              "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
              assessor_without_key(:lastName, valid_assessor_request_body).to_json
            )

          expect(assessor_response.status).to eq(422)
        end

        it 'rejects requests without date of birth' do
          scheme_id = add_scheme
          assessor_response =
            put(
              "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
              assessor_without_key(:dateOfBirth, valid_assessor_request_body).to_json
            )

          expect(assessor_response.status).to eq(422)
        end

        it 'rejects requests with invalid date of birth' do
          scheme_id = add_scheme
          invalid_body = valid_assessor_request_body.dup
          invalid_body[:dateOfBirth] = '02/28/1987'
          assessor_response =
            put(
              "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
              invalid_body.to_json
            )

          expect(assessor_response.status).to eq(422)
        end

        it 'rejects requests with invalid first name' do
          scheme_id = add_scheme
          invalid_body = valid_assessor_request_body.dup
          invalid_body[:firstName] = 1_000
          assessor_response =
            put(
              "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
              invalid_body.to_json
            )

          expect(assessor_response.status).to eq(422)
        end

        it 'rejects requests with invalid last name' do
          scheme_id = add_scheme
          invalid_body = valid_assessor_request_body.dup
          invalid_body[:lastName] = false
          assessor_response =
            put(
              "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
              invalid_body.to_json
            )

          expect(assessor_response.status).to eq(422)
        end

        it 'rejects requests with invalid middle names' do
          scheme_id = add_scheme
          invalid_body = valid_assessor_request_body.dup
          invalid_body[:middleNames] = %w[adsfasd]
          assessor_response =
            put(
              "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
              invalid_body.to_json
            )

          expect(assessor_response.status).to eq(422)
        end
      end

      context 'which has a clashing ID for an assessor on another scheme' do
        it 'Returns a status code 409' do
          first_scheme = add_scheme
          second_scheme = add_scheme('scheme two')

          add_assessor(first_scheme, 'SCHE4001', valid_assessor_request_body)
          second_response =
            add_assessor(second_scheme, 'SCHE4001', valid_assessor_request_body)

          expect(second_response.status).to eq(409)
        end
      end
    end

    context 'when updating an assessor' do
      context 'which is valid with all fields' do
        it 'returns 200 on the update' do
          scheme_id = add_scheme
          add_assessor(scheme_id, 'ASSESSOR99', valid_assessor_request_body)
          second_response =
            add_assessor(
              scheme_id,
              'ASSESSOR99',
              valid_assessor_with_contact_request_body
            )
          expect(second_response.status).to eq(200)
        end

        it 'replaces a previous assessors details successfully' do
          scheme_id = add_scheme
          add_assessor(scheme_id, 'ASSESSOR99', valid_assessor_request_body)
          add_assessor(
            scheme_id,
            'ASSESSOR99',
            valid_assessor_with_contact_request_body
          )
          assessor = fetch_assessor(scheme_id, 'ASSESSOR99')
          expected_response =
            JSON.parse(
              {
                registeredBy: { schemeId: scheme_id, name: 'test scheme' },
                schemeAssessorId: 'ASSESSOR99',
                firstName:
                  assessor_without_key(
                    :middleNames,
                    valid_assessor_with_contact_request_body
                  )[
                    :firstName
                  ],
                middleNames:
                  valid_assessor_with_contact_request_body[:middleNames],
                lastName:
                  assessor_without_key(
                    :middleNames,
                    valid_assessor_with_contact_request_body
                  )[
                    :lastName
                  ],
                dateOfBirth:
                  assessor_without_key(
                    :middleNames,
                    valid_assessor_with_contact_request_body
                  )[
                    :dateOfBirth
                  ],
                contactDetails: {
                  telephoneNumber:
                    assessor_without_key(
                      :middleNames,
                      valid_assessor_with_contact_request_body
                    )[
                      :contactDetails
                    ][
                      :telephoneNumber
                    ],
                  email:
                    assessor_without_key(
                      :middleNames,
                      valid_assessor_with_contact_request_body
                    )[
                      :contactDetails
                    ][
                      :email
                    ]
                }
              }.to_json
            )
          expect(JSON.parse(assessor.body)).to eq(expected_response)
        end
      end

      context 'which has an invalid email' do
        it 'returns error 400' do
          scheme_id = add_scheme

          invalid_request_body = valid_assessor_with_contact_request_body
          invalid_request_body[:contactDetails][:email] = '54'

          expect(
            add_assessor(scheme_id, 'ASSESSOR99', invalid_request_body).status
          ).to eq(422)
        end
      end

      context 'which has a valid email' do
        it 'saves it successfully' do
          scheme_id = add_scheme

          request_body = valid_assessor_with_contact_request_body
          request_body[:contactDetails][:email] = 'mar@ten.com'

          add_assessor(scheme_id, 'ASSESSOR99', request_body).body

          response_body =
            fetch_assessor(scheme_id, 'ASSESSOR99').body
          json_response = JSON.parse(response_body)

          expect(json_response['contactDetails']['email']).to eq('mar@ten.com')
        end
      end

      context 'which has an invalid phone number' do
        it 'returns error 400' do
          scheme_id = add_scheme

          invalid_telephone = '0' * 257

          request_body = valid_assessor_with_contact_request_body
          request_body[:contactDetails][:telephoneNumber] = invalid_telephone

          expect(
            add_assessor(scheme_id, 'ASSESSOR99', request_body).status
          ).to eq(422)
        end
      end

      context 'which has a valid phone number' do
        it 'successfully saves it' do
          scheme_id = add_scheme

          valid_telephone = '0' * 256

          request_body = valid_assessor_with_contact_request_body
          request_body[:contactDetails][:telephoneNumber] = valid_telephone

          add_assessor(scheme_id, 'ASSESSOR99', request_body).body

          response_body =
            fetch_assessor(scheme_id, 'ASSESSOR99').body
          json_response = JSON.parse(response_body)

          expect(json_response['contactDetails']['telephoneNumber']).to eq(
            valid_telephone
          )
        end
      end
    end
  end
end
