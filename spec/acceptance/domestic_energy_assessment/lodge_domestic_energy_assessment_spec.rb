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

  let(:valid_rdsap_xml) do
    File.read File.join Dir.pwd, 'api/schemas/xml/examples/RdSAP-19.01.xml'
  end

  let(:valid_sap_xml) do
    File.read File.join Dir.pwd, 'api/schemas/xml/examples/SAP-17.11.xml'
  end

  context 'when lodging a domestic energy assessment (post)' do
    it 'rejects an assessment with a schema that does not exist' do
      lodge_assessment(
        assessment_id: '0000-0000-0000-0000-0000',
        assessment_body: valid_rdsap_xml,
        accepted_responses: [400],
        schema_name: 'MakeupSAP-19.0'
      )
    end

    context 'when an assessor is not registered' do
      it 'returns status 400' do
        lodge_assessment(
          assessment_id: '0000-0000-0000-0000-0000',
          assessment_body: valid_rdsap_xml,
          accepted_responses: [400]
        )
      end

      it 'returns status 400 with the correct error response' do
        response =
          JSON.parse(
            lodge_assessment(
              assessment_id: '0000-0000-0000-0000-0000',
              assessment_body: valid_rdsap_xml,
              accepted_responses: [400]
            )
              .body
          )

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

        lodge_assessment(
          assessment_id: '0000-0000-0000-0000-0000',
          assessment_body: valid_rdsap_xml,
          accepted_responses: [400],
          auth_data: { scheme_ids: [scheme_id] }
        )
      end

      it 'returns status 400 with the correct error response' do
        scheme_id = add_scheme_and_get_id
        add_assessor(
          scheme_id,
          'Membership-Number0',
          inactive_assessor_request_body
        )

        response =
          JSON.parse(
            lodge_assessment(
              assessment_id: '0000-0000-0000-0000-0000',
              assessment_body: valid_rdsap_xml,
              accepted_responses: [400],
              auth_data: { scheme_ids: [scheme_id] }
            )
              .body
          )

        expect(response['errors'][0]['title']).to eq('Assessor is not active.')
      end
    end

    it 'returns 401 with no authentication' do
      lodge_assessment(
        assessment_id: '0000-0000-0000-0000-0000',
        assessment_body: 'body',
        accepted_responses: [401],
        authenticate: false
      )
    end

    it 'returns 403 with incorrect scopes' do
      lodge_assessment(
        assessment_id: '0000-0000-0000-0000-0000',
        assessment_body: 'body',
        accepted_responses: [403],
        auth_data: { scheme_ids: {} },
        scopes: %w[wrong:scope]
      )
    end

    it 'returns 403 if it is being lodged by the wrong scheme' do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'Membership-Number0', valid_assessor_request_body)
      different_scheme_id = add_scheme_and_get_id('BADSCHEME')

      lodge_assessment(
        assessment_id: '123-344',
        assessment_body: valid_rdsap_xml,
        accepted_responses: [403],
        auth_data: { scheme_ids: [different_scheme_id] }
      )
    end

    it 'returns status 201' do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'Membership-Number0', valid_assessor_request_body)

      lodge_assessment(
        assessment_id: '0000-0000-0000-0000-0000',
        assessment_body: valid_rdsap_xml,
        accepted_responses: [201],
        auth_data: { scheme_ids: [scheme_id] }
      )
    end

    it 'returns json' do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'Membership-Number0', valid_assessor_request_body)

      response =
        lodge_assessment(
          assessment_id: '0000-0000-0000-0000-0000',
          assessment_body: valid_rdsap_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] }
        )

      expect(response.headers['Content-Type']).to eq('application/json')
    end

    it 'returns the assessment as a hash' do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'Membership-Number0', valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment(
            assessment_id: '0000-0000-0000-0000-0000',
            assessment_body: valid_rdsap_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] }
          )
            .body,
          symbolize_names: true
        )

      expect(response[:data]).to be_a Hash
    end

    it 'returns the assessment with the correct keys' do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'Membership-Number0', valid_assessor_request_body)

      response =
        JSON.parse(
          lodge_assessment(
            assessment_id: '0000-0000-0000-0000-0000',
            assessment_body: valid_rdsap_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] }
          )
            .body,
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
          lodge_assessment(
            assessment_id: '0000-0000-0000-0000-0000',
            assessment_body: valid_rdsap_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] }
          )
            .body,
          symbolize_names: true
        )

      expect(response.dig(:data, :schemeAssessorId)).to eq('Membership-Number0')
    end

    context 'when saving a sap assessment' do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_sap_xml }
      let(:response) do
        JSON.parse(fetch_assessment('1234-1234-1234-1234-1234').body)
      end

      before do
        add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)

        assessment_id = doc.at('RRN')
        assessment_id.children = '1234-1234-1234-1234-1234'

        scheme_assessor_id = doc.at('Certificate-Number')
        scheme_assessor_id.children = 'TEST123456'
      end

      it 'returns the data that was lodged' do
        lodge_assessment(
          assessment_id: '1234-1234-1234-1234-1234',
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] },
          schema_name: 'SAP-Schema-17.1'
        )

        expected_response = {
          'addressLine1' => '1 Some Street',
          'addressLine2' => '',
          'addressLine3' => '',
          'addressLine4' => '',
          'addressSummary' => '1 Some Street, Post-Town1, A0 0AA',
          'assessmentId' => '1234-1234-1234-1234-1234',
          'assessor' => {
            'contactDetails' => {
              'email' => 'person@person.com',
              'telephoneNumber' => '010199991010101'
            },
            'dateOfBirth' => '1991-02-25',
            'firstName' => 'Someone',
            'lastName' => 'Person',
            'middleNames' => 'Muddle',
            'qualifications' => {
              'domesticSap' => 'INACTIVE',
              'domesticRdSap' => 'ACTIVE',
              'nonDomesticCc4' => 'INACTIVE',
              'nonDomesticSp3' => 'INACTIVE',
              'nonDomesticDec' => 'INACTIVE',
              'nonDomesticNos3' => 'INACTIVE',
              'nonDomesticNos4' => 'INACTIVE',
              'nonDomesticNos5' => 'INACTIVE'
            },
            'registeredBy' => {
              'name' => 'test scheme', 'schemeId' => scheme_id
            },
            'schemeAssessorId' => 'TEST123456',
            'searchResultsComparisonPostcode' => ''
          },
          'currentEnergyEfficiencyBand' => 'e',
          'currentEnergyEfficiencyRating' => 50,
          'dateOfAssessment' => '2006-05-04',
          'dateOfExpiry' => '2016-05-04',
          'dateRegistered' => '2006-05-04',
          'dwellingType' => 'Dwelling-Type0',
          'heatDemand' => {
            'currentSpaceHeatingDemand' => 30.0,
            'currentWaterHeatingDemand' => 60.0,
            'impactOfCavityInsulation' => -12,
            'impactOfLoftInsulation' => -8,
            'impactOfSolidWallInsulation' => -16
          },
          'postcode' => 'A0 0AA',
          'potentialEnergyEfficiencyBand' => 'e',
          'potentialEnergyEfficiencyRating' => 50,
          'recommendedImprovements' => [],
          'totalFloorArea' => 0.0,
          'town' => 'Post-Town1',
          'typeOfAssessment' => 'RdSAP'
        }

        expect(response['data']).to eq(expected_response)
      end
    end

    context 'when saving an rdsap assessment' do
      let(:scheme_id) { add_scheme_and_get_id }
      let(:doc) { Nokogiri.XML valid_rdsap_xml }
      let(:response) do
        JSON.parse(fetch_assessment('1234-1234-1234-1234-1234').body)
      end

      before do
        add_assessor(scheme_id, 'TEST123456', valid_assessor_request_body)

        assessment_id = doc.at('RRN')
        assessment_id.children = '1234-1234-1234-1234-1234'

        scheme_assessor_id = doc.at('Membership-Number')
        scheme_assessor_id.children = 'TEST123456'
      end

      context 'when an assessment id does not match' do
        it 'returns status 422' do
          lodge_assessment(
            assessment_id: '123-456',
            assessment_body: doc.to_xml,
            accepted_responses: [422],
            auth_data: { scheme_ids: [scheme_id] }
          )
        end
      end

      context 'when an assessment already exists with the same assessment id' do
        it 'returns status 409' do
          lodge_assessment(
            assessment_id: '1234-1234-1234-1234-1234',
            assessment_body: doc.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] }
          )

          lodge_assessment(
            assessment_id: '1234-1234-1234-1234-1234',
            assessment_body: doc.to_xml,
            accepted_responses: [409],
            auth_data: { scheme_ids: [scheme_id] }
          )
        end
      end

      it 'returns the data that was lodged' do
        lodge_assessment(
          assessment_id: '1234-1234-1234-1234-1234',
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] }
        )

        expected_response = {
          'addressLine1' => '1 Some Street',
          'addressLine2' => '',
          'addressLine3' => '',
          'addressLine4' => '',
          'addressSummary' => '1 Some Street, Post-Town1, A0 0AA',
          'assessmentId' => '1234-1234-1234-1234-1234',
          'assessor' => {
            'contactDetails' => {
              'email' => 'person@person.com',
              'telephoneNumber' => '010199991010101'
            },
            'dateOfBirth' => '1991-02-25',
            'firstName' => 'Someone',
            'lastName' => 'Person',
            'middleNames' => 'Muddle',
            'qualifications' => {
              'domesticSap' => 'INACTIVE',
              'domesticRdSap' => 'ACTIVE',
              'nonDomesticCc4' => 'INACTIVE',
              'nonDomesticSp3' => 'INACTIVE',
              'nonDomesticDec' => 'INACTIVE',
              'nonDomesticNos3' => 'INACTIVE',
              'nonDomesticNos4' => 'INACTIVE',
              'nonDomesticNos5' => 'INACTIVE'
            },
            'registeredBy' => {
              'name' => 'test scheme', 'schemeId' => scheme_id
            },
            'schemeAssessorId' => 'TEST123456',
            'searchResultsComparisonPostcode' => ''
          },
          'currentEnergyEfficiencyBand' => 'e',
          'currentEnergyEfficiencyRating' => 50,
          'dateOfAssessment' => '2006-05-04',
          'dateOfExpiry' => '2016-05-04',
          'dateRegistered' => '2006-05-04',
          'dwellingType' => 'Dwelling-Type0',
          'heatDemand' => {
            'currentSpaceHeatingDemand' => 30.0,
            'currentWaterHeatingDemand' => 60.0,
            'impactOfCavityInsulation' => -12,
            'impactOfLoftInsulation' => -8,
            'impactOfSolidWallInsulation' => -16
          },
          'postcode' => 'A0 0AA',
          'potentialEnergyEfficiencyBand' => 'e',
          'potentialEnergyEfficiencyRating' => 50,
          'recommendedImprovements' => [
            {
              'energyPerformanceRatingImprovement' => 50,
              'environmentalImpactRatingImprovement' => 50,
              'greenDealCategoryCode' => '1',
              'improvementCategory' => '6',
              'improvementCode' => '5',
              'improvementType' => 'Z3',
              'indicativeCost' => '5',
              'sequence' => 0,
              'typicalSaving' => '0.0'
            },
            {
              'energyPerformanceRatingImprovement' => 60,
              'environmentalImpactRatingImprovement' => 64,
              'greenDealCategoryCode' => '3',
              'improvementCategory' => '2',
              'improvementCode' => '1',
              'improvementType' => 'Z2',
              'indicativeCost' => '2',
              'sequence' => 1,
              'typicalSaving' => '0.1'
            }
          ],
          'totalFloorArea' => 0.0,
          'town' => 'Post-Town1',
          'typeOfAssessment' => 'RdSAP'
        }

        expect(response['data']).to eq(expected_response)
      end

      it 'can return the correct second address line of the property' do
        address_line_one = doc.search('Address-Line-1')[1]
        address_line_two = Nokogiri::XML::Node.new 'Address-Line-2', doc
        address_line_two.content = '2 test street'
        address_line_one.add_next_sibling address_line_two

        lodge_assessment(
          assessment_id: '1234-1234-1234-1234-1234',
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] }
        )

        expect(response['data']['addressLine2']).to eq('2 test street')
      end

      it 'can return the correct third address line of the property' do
        address_line_one = doc.search('Address-Line-1')[1]
        address_line_three = Nokogiri::XML::Node.new 'Address-Line-3', doc
        address_line_three.content = '3 test street'
        address_line_one.add_next_sibling address_line_three

        lodge_assessment(
          assessment_id: '1234-1234-1234-1234-1234',
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] }
        )

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

        lodge_assessment(
          assessment_id: '1234-1234-1234-1234-1234',
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] }
        )

        expect(response['data']['addressSummary']).to eq(
          '1 Some Street, 2 test street, 3 test street, Post-Town1, A0 0AA'
        )
      end

      it 'can return multiple suggested improvements' do
        lodge_assessment(
          assessment_id: '1234-1234-1234-1234-1234',
          assessment_body: doc.to_xml,
          accepted_responses: [201],
          auth_data: { scheme_ids: [scheme_id] }
        )

        expect(response['data']['recommendedImprovements'].count).to eq(2)
        expect(response['data']['recommendedImprovements'][1]).to eq(
          'energyPerformanceRatingImprovement' => 60,
          'environmentalImpactRatingImprovement' => 64,
          'greenDealCategoryCode' => '3',
          'improvementCategory' => '2',
          'improvementCode' => '1',
          'improvementType' => 'Z2',
          'indicativeCost' => '2',
          'sequence' => 1,
          'typicalSaving' => '0.1'
        )
      end

      context 'when missing optional elements' do
        it 'can return an empty string for address lines' do
          lodge_assessment(
            assessment_id: '1234-1234-1234-1234-1234',
            assessment_body: doc.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] }
          )
          expect(response['data']['addressLine2']).to eq('')
          expect(response['data']['addressLine3']).to eq('')
          expect(response['data']['addressLine4']).to eq('')
        end

        it 'can return nil for heat demand impacts' do
          doc.at('Impact-Of-Loft-Insulation').remove
          doc.at('Impact-Of-Cavity-Insulation').remove
          doc.at('Impact-Of-Solid-Wall-Insulation').remove
          lodge_assessment(
            assessment_id: '1234-1234-1234-1234-1234',
            assessment_body: doc.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] }
          )

          expect(
            response['data']['heatDemand']['impactOfLoftInsulation']
          ).to be_nil
          expect(
            response['data']['heatDemand']['impactOfCavityInsulation']
          ).to be_nil
          expect(
            response['data']['heatDemand']['impactOfSolidWallInsulation']
          ).to be_nil
        end
        it 'can return an empty list of suggested improvements' do
          doc.at('Suggested-Improvements').remove
          lodge_assessment(
            assessment_id: '1234-1234-1234-1234-1234',
            assessment_body: doc.to_xml,
            accepted_responses: [201],
            auth_data: { scheme_ids: [scheme_id] }
          )

          expect(response['data']['recommendedImprovements']).to eq([])
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

        doc = Nokogiri.XML valid_rdsap_xml

        scheme_assessor_id = doc.at('Address')
        scheme_assessor_id.children = ''

        lodge_assessment(
          assessment_id: '0000-0000-0000-0000-0000',
          assessment_body: doc.to_xml,
          accepted_responses: [400]
        )
      end

      it 'rejects an assessment with an incorrect element' do
        scheme_id = add_scheme_and_get_id
        add_assessor(
          scheme_id,
          'Membership-Number0',
          valid_assessor_request_body
        )

        doc = Nokogiri.XML valid_rdsap_xml

        scheme_assessor_id = doc.at('Address')
        scheme_assessor_id.children = '<Postcode>invalid</Postcode>'

        response_body =
          JSON.parse(
            lodge_assessment(
              assessment_id: '0000-0000-0000-0000-0000',
              assessment_body: doc.to_xml,
              accepted_responses: [400]
            )
              .body
          )

        expect(
          response_body['errors'][0]['title']
        ).to include 'This element is not expected.'
      end

      it 'rejects an assessment that violates a business rule' do
        scheme_id = add_scheme_and_get_id
        add_assessor(
          scheme_id,
          'Membership-Number0',
          valid_assessor_request_body
        )

        doc = Nokogiri.XML valid_rdsap_xml
        sequence_one = doc.at('Sequence')
        sequence_one.children = '5'

        lodge_assessment(
          assessment_id: '0000-0000-0000-0000-0000',
          assessment_body: doc.to_xml,
          accepted_responses: [422],
          auth_data: { scheme_ids: [scheme_id] }
        )
      end
    end
  end
end
