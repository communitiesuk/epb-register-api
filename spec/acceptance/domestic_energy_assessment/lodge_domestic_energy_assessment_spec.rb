# frozen_string_literal: true

describe 'Acceptance::LodgeDomesticEnergyAssessment' do
  include RSpecAssessorServiceMixin

  context 'when lodging a domestic assessment (post)' do
    it 'returns 401 with no authentication' do
      lodge_assessment('domestic-epc', '123-456', 'body', [401], false)
    end

    it 'returns 403 with incorrect scopes' do
      lodge_assessment(
        'domestic-epc',
        '123-456',
        'body',
        [403],
        true,
        {},
        %w[wrong:scope]
      )
    end

    it 'returns status 201' do
      lodge_assessment('domestic-epc', '123-456', 'body', [201])
    end

    it 'returns json' do
      response = lodge_assessment('domestic-epc', '123-456', 'body', [201])
      expect(response.headers['Content-Type']).to eq('application/json')
    end
  end
end
