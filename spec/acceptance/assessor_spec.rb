# frozen_string_literal: true

describe 'Acceptance::Assessor' do
  include RSpecAssessorServiceMixin

  let(:valid_assessor_request_body) do
    {
      firstName: 'Someone',
      middleNames: 'Muddle',
      lastName: 'Person',
      dateOfBirth: '1991-02-25',
      searchResultsComparisonPostcode: '',
      qualifications: { domesticRdSap: 'ACTIVE', nonDomesticSp3: 'ACTIVE' }
    }
  end

  let(:valid_assessor_with_contact_request_body) do
    {
      firstName: 'Some',
      middleNames: 'Middle',
      lastName: 'Person',
      dateOfBirth: '1991-02-25',
      contactDetails: {
        telephoneNumber: '010199991010101', email: 'person@person.com'
      },
      searchResultsComparisonPostcode: '',
      qualifications: { domesticRdSap: 'ACTIVE' }
    }
  end

  def fetch_assessor(scheme_id, assessor_id)
    authenticate_and do
      get("/api/schemes/#{scheme_id}/assessors/#{assessor_id}")
    end
  end

  def add_assessor(scheme_id, assessor_id, body)
    authenticate_and do
      put("/api/schemes/#{scheme_id}/assessors/#{assessor_id}", body.to_json)
    end
  end

  def add_scheme(name = 'test scheme')
    authenticate_and do
      JSON.parse(post('/api/schemes', { name: name }.to_json).body)['schemeId']
    end
  end

  def assessor_without_key(missing, request_body)
    assessor = request_body.dup
    assessor.delete(missing)
    assessor
  end

  context "when a scheme doesn't exist" do
    it 'returns status 404 for a get' do
      expect(fetch_assessor(20, 'SCHEME4233').status).to eq(404)
    end

    it 'returns status 404 for a PUT' do
      expect(
        add_assessor(20, 'SCHEME4532', valid_assessor_request_body).status
      ).to eq(404)
    end

    context 'and the client is unauthenticated' do
      it 'returns status 401 for a get' do
        expect(get('/api/schemes/20/assessors/SCHEME4233').status).to eq(401)
      end

      it 'returns status 401 for a PUT' do
        expect(
          put(
            '/api/schemes/20/assessors/SCHEME4532',
            valid_assessor_request_body.to_json
          )
            .status
        ).to eq(401)
      end
    end
  end

  context "when an assessor doesn't exist" do
    let!(:scheme_id) { add_scheme }

    it 'returns status 404' do
      expect(fetch_assessor(scheme_id, 'SCHE2354246').status).to eq(404)
    end

    context 'and the client is unauthenticated' do
      it 'returns status 401' do
        expect(
          get("/api/schemes/#{scheme_id}/assessors/SCHE2354246").status
        ).to eq(401)
      end
    end
  end

  context 'when getting an assessor on the wrong scheme' do
    it 'returns status 404' do
      scheme_id = add_scheme
      second_scheme_id = add_scheme('second scheme')
      add_assessor(second_scheme_id, 'SCHE987654', valid_assessor_request_body)

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
              contactDetails: {},
              searchResultsComparisonPostcode: '',
              qualifications: {
                domesticRdSap: 'ACTIVE', nonDomesticSp3: 'ACTIVE'
              }
            }.to_json
          )
        response = JSON.parse(fetch_assessor(scheme_id, 'SCHEME4233').body)
        expect(response).to eq(expected_response)
      end

      it 'returns EPC domestic qualification as inactive by default' do
        scheme_id = add_scheme
        add_assessor(
          scheme_id,
          'SCHEME4233',
          assessor_without_key(:qualifications, valid_assessor_request_body)
        )
        response = JSON.parse(fetch_assessor(scheme_id, 'SCHEME4233').body)
        expect(response['qualifications']['domesticRdSap']).to eq('INACTIVE')
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
              dateOfBirth: valid_assessor_request_body[:dateOfBirth],
              searchResultsComparisonPostcode:
                valid_assessor_request_body[:searchResultsComparisonPostcode],
              qualifications: {
                domesticRdSap: 'ACTIVE', nonDomesticSp3: 'ACTIVE'
              },
              contactDetails: {}
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
              firstName: valid_assessor_request_body[:firstName],
              lastName: valid_assessor_request_body[:lastName],
              dateOfBirth: valid_assessor_request_body[:dateOfBirth],
              searchResultsComparisonPostcode:
                valid_assessor_request_body[:searchResultsComparisonPostcode],
              qualifications: valid_assessor_request_body[:qualifications],
              contactDetails: {}
            }.to_json
          )

        expect(assessor_response).to eq(expected_response)
      end
    end

    context 'which is invalid' do
      it "rejects anything that isn't JSON" do
        scheme_id = add_scheme
        assessor_response =
          authenticate_and do
            put(
              "/api/schemes/#{scheme_id}/assessors/thebrokenassessor",
              '>>>this is not json<<<'
            )
          end

        expect(assessor_response.status).to eq(400)
      end

      it 'rejects an empty request body' do
        scheme_id = add_scheme
        assessor_response =
          authenticate_and do
            put("/api/schemes/#{scheme_id}/assessors/thebrokenassessor")
          end

        expect(assessor_response.status).to eq(400)
      end

      it 'rejects requests without firstname' do
        scheme_id = add_scheme
        assessor_response =
          add_assessor(
            scheme_id,
            'thebrokenassessor',
            assessor_without_key(:firstName, valid_assessor_request_body)
          )

        expect(assessor_response.status).to eq(422)
      end

      it 'rejects requests without last name' do
        scheme_id = add_scheme
        assessor_response =
          add_assessor(
            scheme_id,
            'thebrokenassessor',
            assessor_without_key(:lastName, valid_assessor_request_body)
          )

        expect(assessor_response.status).to eq(422)
      end

      it 'rejects requests without date of birth' do
        scheme_id = add_scheme
        assessor_response =
          add_assessor(
            scheme_id,
            'thebrokenassessor',
            assessor_without_key(:dateOfBirth, valid_assessor_request_body)
          )

        expect(assessor_response.status).to eq(422)
      end

      it 'rejects requests with invalid date of birth' do
        scheme_id = add_scheme
        invalid_body = valid_assessor_request_body.dup
        invalid_body[:dateOfBirth] = '02/28/1987'
        assessor_response =
          add_assessor(scheme_id, 'thebrokenassessor', invalid_body)

        expect(assessor_response.status).to eq(422)
      end

      it 'rejects requests with invalid first name' do
        scheme_id = add_scheme
        invalid_body = valid_assessor_request_body.dup
        invalid_body[:firstName] = 1_000
        assessor_response =
          add_assessor(scheme_id, 'thebrokenassessor', invalid_body)

        expect(assessor_response.status).to eq(422)
      end

      it 'rejects requests with invalid last name' do
        scheme_id = add_scheme
        invalid_body = valid_assessor_request_body.dup
        invalid_body[:lastName] = false
        assessor_response =
          add_assessor(scheme_id, 'thebrokenassessor', invalid_body)

        expect(assessor_response.status).to eq(422)
      end

      it 'rejects requests with invalid middle names' do
        scheme_id = add_scheme
        invalid_body = valid_assessor_request_body.dup
        invalid_body[:middleNames] = %w[adsfasd]
        assessor_response =
          add_assessor(scheme_id, 'thebrokenassessor', invalid_body)

        expect(assessor_response.status).to eq(422)
      end

      it 'rejects an assessor qualification that isnt a valid status' do
        scheme_id = add_scheme
        invalid_body = valid_assessor_request_body.dup
        invalid_body[:qualifications] = { domesticRdSap: 'horse' }
        assessor_response =
          add_assessor(scheme_id, 'thebrokenassessor', invalid_body)

        expect(assessor_response.status).to eq(422)
      end

      it 'rejects a search results comparison postcode that isnt a string' do
        scheme_id = add_scheme
        invalid_body = valid_assessor_request_body.dup
        invalid_body[:searchResultsComparisonPostcode] = 25
        assessor_response =
          add_assessor(scheme_id, 'thebrokenassessor', invalid_body)

        expect(assessor_response.status).to eq(422)
      end
    end

    context 'which has a clashing ID for an assessor on another scheme' do
      it 'Returns a status code 409' do
        first_scheme = add_scheme
        second_scheme = add_scheme 'scheme two'

        add_assessor(first_scheme, 'SCHE4001', valid_assessor_request_body)
        second_response =
          add_assessor(second_scheme, 'SCHE4001', valid_assessor_request_body)

        expect(second_response.status).to eq(409)
      end
    end

    context 'which has an escaped assessor scheme id' do
      let(:escaped_assessor_scheme_id) { 'TEST%2F000000' }

      it 'adds an assessor' do
        scheme_id = add_scheme

        add_assessor_response =
          add_assessor scheme_id,
                       escaped_assessor_scheme_id,
                       valid_assessor_with_contact_request_body

        expect(add_assessor_response.status).to eq 201
      end

      it 'fetches an assessor' do
        scheme_id = add_scheme

        add_assessor scheme_id,
                     escaped_assessor_scheme_id,
                     valid_assessor_with_contact_request_body

        fetch_assessor_response =
          fetch_assessor(scheme_id, escaped_assessor_scheme_id)

        expect(fetch_assessor_response.status).to eq 200
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
              },
              searchResultsComparisonPostcode: '',
              qualifications: {
                domesticRdSap: 'ACTIVE', nonDomesticSp3: 'INACTIVE'
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

        response_body = fetch_assessor(scheme_id, 'ASSESSOR99').body
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

        add_assessor(scheme_id, 'ASSESSOR99', request_body)

        response_body = fetch_assessor(scheme_id, 'ASSESSOR99').body

        json_response = JSON.parse(response_body)

        expect(json_response['contactDetails']['telephoneNumber']).to eq(
          valid_telephone
        )
      end
    end
  end

  context 'when searching for an assessor by name' do
    context 'when there are no results' do
      it 'returns the status code 404' do
        scheme_id = add_scheme

        add_assessor(scheme_id, 'SCHE55443', valid_assessor_request_body)

        search_response =
          authenticate_and { get '/api/assessors/?name=Marten%20Sheikh' }

        expect(search_response.status).to eq(404)
      end
    end

    context 'when there are results' do
      it 'returns the assessors details' do
        scheme_id = add_scheme

        add_assessor(scheme_id, 'SCHE55443', valid_assessor_request_body)

        search_response =
          authenticate_and { get '/api/assessors?name=Someone%20Person' }.body

        response = JSON.parse(search_response)

        expect(response['results'][0]).to eq(
          JSON.parse(
            {
              registeredBy: { schemeId: scheme_id, name: 'test scheme' },
              schemeAssessorId: 'SCHE55443',
              firstName: valid_assessor_request_body[:firstName],
              lastName: valid_assessor_request_body[:lastName],
              middleNames: valid_assessor_request_body[:middleNames],
              dateOfBirth: valid_assessor_request_body[:dateOfBirth],
              searchResultsComparisonPostcode:
                valid_assessor_request_body[:searchResultsComparisonPostcode],
              qualifications: valid_assessor_request_body[:qualifications],
              contactDetails: {}
            }.to_json
          )
        )
      end

      it 'lets you search for swapped names' do
        scheme_id = add_scheme

        add_assessor(scheme_id, 'SCHE55443', valid_assessor_request_body)

        search_response =
          authenticate_and { get '/api/assessors?name=Person%20Someone' }.body

        response = JSON.parse(search_response)

        expect(response['results'].size).to eq(1)
      end

      it 'lets you search for half names' do
        scheme_id = add_scheme

        add_assessor(scheme_id, 'SCHE55443', valid_assessor_request_body)

        search_response =
          authenticate_and { get '/api/assessors?name=Per%20Some' }.body

        response = JSON.parse(search_response)

        expect(response['results'].size).to eq(1)
      end
    end
  end
end
