# frozen_string_literal: true

module UseCase
  class LodgeAssessment
    def initialize(domestic_energy_assessments_gateway, assessors_gateway)
      @domestic_energy_assessments_gateway = domestic_energy_assessments_gateway
      @assessors_gateway = assessors_gateway
    end

    def execute(body, _assessment_id, _content_type)
      scheme_assessor_id = fetch(body, :Membership_Number)

      assessor = @assessors_gateway.fetch scheme_assessor_id

      assessment =
        Domain::DomesticEnergyAssessment.new(
          '2019-01-01',
          '2019-01-01',
          fetch(body, :Dwelling_Type),
          'RdSAP',
          '500',
          fetch(body, :RRN),
          assessor,
          'Blah di blah',
          fetch(body, :Energy_Rating_Current).to_i,
          fetch(body, :Energy_Rating_Potential).to_i,
          'E20SZ',
          '2020-01-01',
          'Makeup Street',
          'Beauty Town',
          '',
          '',
          'Beer-king town',
          100,
          50,
          10,
          20,
          30,
          []
        )

      @domestic_energy_assessments_gateway.insert_or_update(assessment)

      assessment
    end

    private

    def fetch(hash, key)
      return hash[key] if hash.fetch(key, false)

      hash.each_key do |hash_key|
        result = fetch(hash[hash_key], key) if hash[hash_key].is_a? Hash
        return result if result
      end

      false
    end
  end
end
