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

  let(:inactive_assessor_request_body) do
    {
      firstName: 'Someone',
      middleNames: 'Muddle',
      lastName: 'Person',
      dateOfBirth: '1991-02-25',
      searchResultsComparisonPostcode: '',
      qualifications: { domesticRdSap: 'INACTIVE' },
      contactDetails: {
        telephoneNumber: '010199991010101', email: 'person@person.com'
      }
    }
  end

  let(:valid_xml) do
    File.read File.join Dir.pwd, 'api/schemas/xml/examples/RdSAP-19.01.xml'
  end

  context 'when lodging a domestic energy assessment (post)' do
    context 'when an assessor is not registered' do
      it 'returns status 400' do
        lodge_assessment('123-456', valid_xml, [400])
      end

      it 'returns status 400 with the correct error response' do
        response = JSON.parse lodge_assessment('123-456', valid_xml, [400]).body

        expect(response['errors'][0]['title']).to eq(
          'Assessor is not registered.'
        )
      end
    end

    context 'when an assessor is inactive' do
      it 'returns status 400' do
        scheme_id = add_scheme_and_get_id
        add_assessor(
          scheme_id,
          'Membership-Number0',
          inactive_assessor_request_body
        )

        lodge_assessment('123-456', valid_xml, [400])
      end

      it 'returns status 400 with the correct error response' do
        scheme_id = add_scheme_and_get_id
        add_assessor(
          scheme_id,
          'Membership-Number0',
          inactive_assessor_request_body
        )

        response = JSON.parse lodge_assessment('123-456', valid_xml, [400]).body

        expect(response['errors'][0]['title']).to eq('Assessor is not active.')
      end
    end

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

    context 'when saving an assessment' do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_xml }
      let(:response) do
        JSON.parse fetch_assessment('1234-1234-1234-1234-1234').body
      end

      before do
        add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)

        assessment_id = doc.at('RRN')
        assessment_id.children = '1234-1234-1234-1234-1234'

        scheme_assessor_id = doc.at('Membership-Number')
        scheme_assessor_id.children = 'TEST123456'
      end

      it 'can return the correct scheme assessor id' do
        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(response['data']['assessor']['schemeAssessorId']).to eq(
          'TEST123456'
        )
      end

      it 'can return the correct dwelling type' do
        dwelling_type = doc.at('Dwelling-Type')
        dwelling_type.children = 'valid dwelling type'

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(response['data']['dwellingType']).to eq('valid dwelling type')
      end

      it 'can return the correct current energy efficiency band' do
        current_energy_efficiency_ratng = doc.at('Energy-Rating-Current')
        current_energy_efficiency_ratng.children = '80'

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(response['data']['currentEnergyEfficiencyBand']).to eq('c')
      end

      it 'can return the correct potential energy efficiency band' do
        potential_energy_efficiency_ratng = doc.at('Energy-Rating-Potential')
        potential_energy_efficiency_ratng.children = '90'

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(response['data']['potentialEnergyEfficiencyBand']).to eq('b')
      end

      it 'can return the correct date of assessment' do
        date_of_assessment = doc.at('Inspection-Date')
        date_of_assessment.children = '2006-10-25'

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(response['data']['dateOfAssessment']).to eq('2006-10-25')
      end

      it 'can return the correct registered date' do
        date_registered = doc.at('Registration-Date')
        date_registered.children = '2006-10-30'

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(response['data']['dateRegistered']).to eq('2006-10-30')
      end

      it 'can return the correct expiry date' do
        date_of_assessment = doc.at('Inspection-Date')
        date_of_assessment.children = '2006-10-25'

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(response['data']['dateOfExpiry']).to eq('2016-10-25')
      end

      it 'can return the correct total floor area' do
        total_floor_area = doc.at('Total-Floor-Area')
        total_floor_area.children = '100'

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(response['data']['totalFloorArea']).to eq(100.0)
      end

      it 'can return the correct postcode of the property' do
        postcode = doc.search('Postcode')[1]
        postcode.content = 'AB4A 9AA'

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(response['data']['postcode']).to eq('AB4A 9AA')
      end

      it 'can return the correct town of the property' do
        town = doc.search('Post-Town')[1]
        town.content = 'London'

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(response['data']['town']).to eq('London')
      end

      it 'can return the correct first address line of the property' do
        address_line_one = doc.search('Address-Line-1')[1]
        address_line_one.content = '1 test street'

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(response['data']['addressLine1']).to eq('1 test street')
      end

      it 'can return the correct second address line of the property' do
        address_line_one = doc.search('Address-Line-1')[1]
        address_line_two = Nokogiri::XML::Node.new 'Address-Line-2', doc
        address_line_two.content = '2 test street'
        address_line_one.add_next_sibling address_line_two

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(response['data']['addressLine2']).to eq('2 test street')
      end

      it 'can return the correct third address line of the property' do
        address_line_one = doc.search('Address-Line-1')[1]
        address_line_three = Nokogiri::XML::Node.new 'Address-Line-3', doc
        address_line_three.content = '3 test street'
        address_line_one.add_next_sibling address_line_three

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(response['data']['addressLine3']).to eq('3 test street')
      end

      it 'can return the correct address summary of the property' do
        address_line_one = doc.search('Address-Line-1')[1]

        address_line_two = Nokogiri::XML::Node.new 'Address-Line-2', doc
        address_line_two.content = '2 test street'
        address_line_one.add_next_sibling address_line_two

        address_line_three = Nokogiri::XML::Node.new 'Address-Line-3', doc
        address_line_three.content = '3 test street'
        address_line_two.add_next_sibling address_line_three

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(response['data']['addressSummary']).to eq(
          '1 Some Street, 2 test street, 3 test street, Post-Town1, A0 0AA'
        )
      end

      it 'can return the correct sequence of the improvement' do
        sequence = doc.at('Sequence')
        sequence.children = '1'

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(
          response['data']['recommendedImprovements'][0]['sequence']
        ).to eq(1)
      end

      it 'can return the correct improvement category of the improvement' do
        improvement_category = doc.at('Improvement-Category')
        improvement_category.children = '2'

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(
          response['data']['recommendedImprovements'][0]['improvementCategory']
        ).to eq('2')
      end

      it 'can return the correct improvement type of the improvement' do
        improvement_type = doc.at('Improvement-Type')
        improvement_type.children = 'A'

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(
          response['data']['recommendedImprovements'][0]['improvementType']
        ).to eq('A')
      end

      it 'can return the correct typical saving of the improvement' do
        typical_saving = doc.at('Typical-Saving')
        typical_saving.children = '123.456'

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(
          response['data']['recommendedImprovements'][0]['typicalSaving']
        ).to eq('123.456')
      end

      it 'can return the correct energy performance rating of the improvement' do
        energy_performance_rating = doc.at('Energy-Performance-Rating')
        energy_performance_rating.children = '95'

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(
          response['data']['recommendedImprovements'][0][
            'energyPerformanceRating'
          ]
        ).to eq('95')
      end

      it 'can return the correct environmental impact rating of the improvement' do
        environmental_impact_rating = doc.at('Environmental-Impact-Rating')
        environmental_impact_rating.children = '70'

        lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

        expect(
          response['data']['recommendedImprovements'][0][
            'environmentalImpactRating'
          ]
        ).to eq('70')
      end

      context 'when missing optional elements' do
        it 'can return an empty string' do
          lodge_assessment('1234-1234-1234-1234-1234', doc.to_xml, [201])

          expect(response['data']['addressLine2']).to eq('')
          expect(response['data']['addressLine3']).to eq('')
          expect(response['data']['addressLine4']).to eq('')
        end
      end
    end

    context 'when rejecting an assessment' do
      it 'rejects an assessment without an address' do
        scheme_id = add_scheme_and_get_id
        add_assessor(
          scheme_id,
          'Membership-Number0',
          valid_assessor_request_body
        )

        doc = Nokogiri.XML valid_xml

        scheme_assessor_id = doc.at('Address')
        scheme_assessor_id.children = ''

        lodge_assessment('123-456', doc.to_xml, [400])
      end

      it 'rejects an assessment with an incorrect element' do
        scheme_id = add_scheme_and_get_id
        add_assessor(
          scheme_id,
          'Membership-Number0',
          valid_assessor_request_body
        )

        doc = Nokogiri.XML valid_xml

        scheme_assessor_id = doc.at('Address')
        scheme_assessor_id.children = '<Postcode>invalid</Postcode>'

        response_body =
          JSON.parse lodge_assessment('123-456', doc.to_xml, [400]).body

        expect(
          response_body['errors'][0]['title']
        ).to include 'This element is not expected.'
      end
    end
  end
end
