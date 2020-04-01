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
        [401],
        false,
        {},
        %w[wrong:scope]
      )
    end
  end
end
