# frozen_string_literal: true

describe 'Acceptance::LodgeDomesticEnergyAssessment' do
  include RSpecAssessorServiceMixin

  let(:valid_assessor_request_body) do
    {
      firstName: 'Someone',
      middleNames: 'Muddle',
      lastName: 'Person',
      dateOfBirth: '1991-02-25',
      searchResultsComparisonPostcode: '',
      qualifications: { domesticRdSap: 'ACTIVE' },
      contactDetails: {
        telephoneNumber: '010199991010101', email: 'person@person.com'
      }
    }
  end

  let(:valid_xml) do
    File.read File.join Dir.pwd, 'api/schemas/xml/examples/RdSAP-19.01.xml'
  end

  context 'when lodging a domestic energy assessment (post)' do
    it 'returns 401 with no authentication' do
      lodge_assessment('123-456', 'body', [401], false)
    end

    it 'returns 403 with incorrect scopes' do
      lodge_assessment('123-456', 'body', [403], true, {}, %w[wrong:scope])
    end

    it 'returns status 201' do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'Membership-Number0', valid_assessor_request_body)

      lodge_assessment('123-456', valid_xml, [201])
    end

    it 'returns json' do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'Membership-Number0', valid_assessor_request_body)

      response = lodge_assessment('123-456', valid_xml, [201])

      expect(response.headers['Content-Type']).to eq('application/json')
    end

    it 'returns the assessment as a hash' do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'Membership-Number0', valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment('123-456', valid_xml, [201]).body,
          symbolize_names: true
        )

      expect(response[:data]).to be_a Hash
    end

    it 'returns the assessment with the correct keys' do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'Membership-Number0', valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment('123-456', valid_xml, [201]).body,
          symbolize_names: true
        )

      expect(response[:data].keys).to match_array(
        %i[
          dateOfAssessment
          dateRegistered
          dwellingType
          typeOfAssessment
          totalFloorArea
          assessmentId
          schemeAssessorId
          addressSummary
          currentEnergyEfficiencyRating
          potentialEnergyEfficiencyRating
          postcode
          dateOfExpiry
          addressLine1
          addressLine2
          addressLine3
          addressLine4
          town
          heatDemand
          currentEnergyEfficiencyBand
          potentialEnergyEfficiencyBand
          recommendedImprovements
        ]
      )
    end

    it 'returns the correct scheme assessor id' do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'Membership-Number0', valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment('123-456', valid_xml, [201]).body,
          symbolize_names: true
        )

      expect(response.dig(:data, :schemeAssessorId)).to eq('Membership-Number0')
    end

    it 'can successfully save an assessment' do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)

      doc = Nokogiri.XML valid_xml

      scheme_assessor_id = doc.at('Membership-Number')
      scheme_assessor_id.children = 'TEST123456'

      assessment_id = doc.at('RRN')
      assessment_id.children = '1234-1234-1234-1234-1234'

      lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

      response = JSON.parse fetch_assessment('1234-1234-1234-1234-1234').body

      expect(response['data']['assessor']['schemeAssessorId']).to eq(
        'TEST123456'
      )
    end
  end
end
