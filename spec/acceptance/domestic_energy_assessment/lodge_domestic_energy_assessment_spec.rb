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

  context 'when lodging a domestic assessment (post)' do
    it 'returns 401 with no authentication' do
      lodge_assessment('123-456', 'body', [401], false)
    end

    it 'returns 403 with incorrect scopes' do
      lodge_assessment('123-456', 'body', [403], true, {}, %w[wrong:scope])
    end

    it 'returns status 201' do
      lodge_assessment('123-456', valid_xml, [201])
    end

    it 'returns json' do
      response = lodge_assessment('123-456', valid_xml, [201])
      expect(response.headers['Content-Type']).to eq('application/json')
    end

    it 'returns the assessment as a hash' do
      response =
        JSON.parse(
          lodge_assessment('123-456', valid_xml, [201]).body,
          symbolize_names: true
        )

      expect(response[:data]).to be_a Hash
    end

    it 'returns the assessment in the correct format' do
      response =
        JSON.parse(
          lodge_assessment('123-456', valid_xml, [201]).body,
          symbolize_names: true
        )

      expect(response[:data][:rdSAPReport].keys).to match_array(
        [
          :xmlns,
          :"xmlns:xsi",
          :"xsi:schemaLocation",
          :calculationSoftwareName,
          :calculationSoftwareVersion,
          :userInterfaceName,
          :userInterfaceVersion,
          :schemaVersionOriginal,
          :sAPVersion,
          :pCDFRevisionNumber,
          :previousEpcCheck,
          :energyAssessment,
          :reportHeader,
          :insuranceDetails,
          :externalDefinitionsRevisionNumber
        ]
      )
    end

    it 'returns the assessment in the correct format' do
      response =
        JSON.parse(
          lodge_assessment('123-456', valid_xml, [201]).body,
          symbolize_names: true
        )

      expect(
        response.dig(
          :data,
          :rdSAPReport,
          :reportHeader,
          :energyAssessor,
          :identificationNumber,
          :membershipNumber
        )
      ).to eq('Membership-Number0')
    end

    it 'can successfully save an assessment' do
      # scheme_id = add_scheme_and_get_id
      # add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)
      #
      # lodgement_xml = valid_xml
      #
      # lodgement_xml.gsub('<Membership-Number>Membership-Number0</Membership-Number>', '<Membership-Number>TEST123456</Membership-Number>')
      # lodgement_xml.gsub('<RRN>0000-0000-0000-0000-0000</RRN>', '<RRN>123-456</RRN>')
      #
      # lodge_assessment('123-456', lodgement_xml, [201])
      #
      # response = fetch_assessment('123-456')
      #
      # expect(response['data']['assessor']['schemeAssessorId']).to eq('123-456')
    end
  end
end
