# frozen_string_literal: true

describe AssessorService do
  describe 'The Assessor API' do
    VALID_ASSESSOR_REQUEST_BODY = {
      firstName: 'Some',
      middleNames: 'middle',
      lastName: 'Person',
      dateOfBirth: '1991-02-25'
    }.freeze

    def fetch_assessor(scheme_id, assessor_id)
      get "/api/schemes/#{scheme_id}/assessors/#{assessor_id}"
    end

    def add_assessor(scheme_id, assessor_id, body)
      put("/api/schemes/#{scheme_id}/assessors/#{assessor_id}", body.to_json)
    end

    def add_scheme(name = 'test scheme')
      JSON.parse(post('/api/schemes', { name: name }.to_json).body)['schemeId']
    end

    def assessor_without_key(missing)
      assessor = VALID_ASSESSOR_REQUEST_BODY.dup
      assessor.delete(missing)
      assessor
    end

    context 'When a scheme doesnt exist' do
      it 'returns status 404 for a get' do
        expect(fetch_assessor(20, 'SCHEME4233').status).to eq(404)
      end

      it 'returns status 404 for a PUT' do
        expect(
          add_assessor(20, 'SCHEME4532', VALID_ASSESSOR_REQUEST_BODY).status
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
        second_scheme_id = add_scheme(name = 'second scheme')
        add_assessor(
          second_scheme_id,
          'SCHE987654',
          VALID_ASSESSOR_REQUEST_BODY
        )

        expect(fetch_assessor(scheme_id, 'SCHE987654').status).to eq(404)
      end
    end

    context 'when getting an assessor' do
      context 'and the assessor exists on the correct scheme' do
        it 'returns status 200 for a get' do
          scheme_id = add_scheme
          add_assessor(scheme_id, 'SCHEME4233', VALID_ASSESSOR_REQUEST_BODY)
          expect(fetch_assessor(scheme_id, 'SCHEME4233').status).to eq(200)
        end
      end
    end

    context 'when creating an assessor' do
      context 'which is valid with all fields' do
        it 'returns 201 created' do
          scheme_id = add_scheme
          assessor_response =
            add_assessor(scheme_id, 'SCHE55443', VALID_ASSESSOR_REQUEST_BODY)

          expect(assessor_response.status).to eq(201)
        end

        it 'returns assessor details with scheme details' do
          scheme_id = add_scheme
          assessor_response =
            JSON.parse(
              add_assessor(scheme_id, 'SCHE55443', VALID_ASSESSOR_REQUEST_BODY)
                .body
            )

          expected_response =
            JSON.parse(
              {
                registeredBy: { schemeId: scheme_id.to_s, name: 'test scheme' },
                schemeAssessorId: 'SCHE55443',
                firstName: VALID_ASSESSOR_REQUEST_BODY[:firstName],
                middleNames: VALID_ASSESSOR_REQUEST_BODY[:middleNames],
                lastName: VALID_ASSESSOR_REQUEST_BODY[:lastName],
                dateOfBirth: VALID_ASSESSOR_REQUEST_BODY[:dateOfBirth]
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
              assessor_without_key(:middleNames)
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
                assessor_without_key(:middleNames)
              )
                .body
            )

          expected_response =
            JSON.parse(
              {
                registeredBy: { schemeId: scheme_id.to_s, name: 'test scheme' },
                schemeAssessorId: 'SCHE55443',
                firstName: assessor_without_key(:middleNames)[:firstName],
                lastName: assessor_without_key(:middleNames)[:lastName],
                dateOfBirth: assessor_without_key(:middleNames)[:dateOfBirth]
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
              assessor_without_key(:firstName)
            )

          expect(assessor_response.status).to eq(400)
        end

        it 'rejects requests without last name' do
          scheme_id = add_scheme
          assessor_response =
            put(
              "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
              assessor_without_key(:lastName)
            )

          expect(assessor_response.status).to eq(400)
        end

        it 'rejects requests without date of birth' do
          scheme_id = add_scheme
          assessor_response =
            put(
              "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
              assessor_without_key(:dateOfBirth)
            )

          expect(assessor_response.status).to eq(400)
        end

        it 'rejects requests with invalid date of birth' do
          scheme_id = add_scheme
          invalid_body = VALID_ASSESSOR_REQUEST_BODY.dup
          invalid_body[:dateOfBirth] = '02/28/1987'
          assessor_response =
            put(
              "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
              invalid_body.to_json
            )

          expect(assessor_response.status).to eq(400)
        end

        it 'rejects requests with invalid first name' do
          scheme_id = add_scheme
          invalid_body = VALID_ASSESSOR_REQUEST_BODY.dup
          invalid_body[:firstName] = 1_000
          assessor_response =
            put(
              "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
              invalid_body.to_json
            )

          expect(assessor_response.status).to eq(400)
        end

        it 'rejects requests with invalid last name' do
          scheme_id = add_scheme
          invalid_body = VALID_ASSESSOR_REQUEST_BODY.dup
          invalid_body[:lastName] = false
          assessor_response =
            put(
              "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
              invalid_body.to_json
            )

          expect(assessor_response.status).to eq(400)
        end

        it 'rejects requests with invalid middle names' do
          scheme_id = add_scheme
          invalid_body = VALID_ASSESSOR_REQUEST_BODY.dup
          invalid_body[:middleNames] = %w[adsfasd]
          assessor_response =
            put(
              "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
              invalid_body.to_json
            )

          expect(assessor_response.status).to eq(400)
        end
      end

      context 'which has a clashing ID for an assessor on another scheme' do
        it 'Returns a status code 409' do
          first_scheme = add_scheme
          second_scheme = add_scheme(name = 'scheme two')

          add_assessor(first_scheme, 'SCHE4001', VALID_ASSESSOR_REQUEST_BODY)
          second_response =
            add_assessor(second_scheme, 'SCHE4001', VALID_ASSESSOR_REQUEST_BODY)

          expect(second_response.status).to eq(409)
        end
      end
    end

    context 'when updating an assessor' do
      context 'which is valid with all fields' do
        it 'returns 200 on the update' do
          scheme_id = add_scheme
          add_assessor(scheme_id, 'ASSESSOR99', VALID_ASSESSOR_REQUEST_BODY)
          second_response =
            add_assessor(scheme_id, 'ASSESSOR99', VALID_ASSESSOR_REQUEST_BODY)
          expect(second_response.status).to eq(200)
        end
      end
    end
  end
end
