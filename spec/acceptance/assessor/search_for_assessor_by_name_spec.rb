describe 'Searching for an assessor by name' do
  include RSpecAssessorServiceMixin
  let(:valid_assessor_request) do
    {
      firstName: 'Some',
      middleNames: 'Middle',
      lastName: 'Person',
      dateOfBirth: '1991-02-25',
      contactDetails: {
        telephoneNumber: '010199991010101', email: 'person@person.com'
      },
      searchResultsComparisonPostcode: '',
      qualifications: {
        domesticRdSap: 'ACTIVE',
        nonDomesticSp3: 'ACTIVE',
        nonDomesticCc4: 'ACTIVE',
        nonDomesticDec: 'ACTIVE'
      }
    }
  end

  context 'when there are no results' do
    it 'returns an empty list' do
      add_scheme_then_assessor(valid_assessor_request)
      response = JSON.parse(assessors_search_by_name('Marten%20Sheikh').body)
      expect(response['data']['assessors']).to eq([])
    end
  end

  context 'when there are results' do
    it 'returns the assessors details' do
      scheme_id = add_scheme_and_get_id
      add_assessor(scheme_id, 'SCHE55443', valid_assessor_request)
      search_response = assessors_search_by_name('Some%20Person').body
      response = JSON.parse(search_response)

      expect(response['data']['assessors'][0]).to eq(
        JSON.parse(
          {
            registeredBy: { schemeId: scheme_id, name: 'test scheme' },
            schemeAssessorId: 'SCHE55443',
            firstName: valid_assessor_request[:firstName],
            lastName: valid_assessor_request[:lastName],
            middleNames: valid_assessor_request[:middleNames],
            dateOfBirth: valid_assessor_request[:dateOfBirth],
            searchResultsComparisonPostcode:
              valid_assessor_request[:searchResultsComparisonPostcode],
            qualifications: valid_assessor_request[:qualifications],
            contactDetails: valid_assessor_request[:contactDetails]
          }.to_json
        )
      )
    end

    it 'lets you search for swapped names' do
      add_scheme_then_assessor(valid_assessor_request)
      search_response = assessors_search_by_name('Person%20Some')
      response = JSON.parse(search_response.body)

      expect(response['data']['assessors'].size).to eq(1)
    end

    it 'lets you search for half names' do
      add_scheme_then_assessor(valid_assessor_request)
      search_response = assessors_search_by_name('Per%20Some')
      response = JSON.parse(search_response.body)

      expect(response['data']['assessors'].size).to eq(1)
    end
  end
end
