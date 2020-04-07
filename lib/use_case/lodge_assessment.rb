# frozen_string_literal: true

module UseCase
  class LodgeAssessment
    class InactiveAssessorException < StandardError; end

    def initialize(domestic_energy_assessments_gateway, assessors_gateway)
      @domestic_energy_assessments_gateway = domestic_energy_assessments_gateway
      @assessors_gateway = assessors_gateway
    end

    def execute(body, _assessment_id, _content_type)
      scheme_assessor_id = fetch(body, :Membership_Number)
      address = body[:RdSAP_Report][:Report_Header][:Property][:Address]

      address_summary =
        [
          address[:Address_Line_1],
          address[:Address_Line_2],
          address[:Address_Line_3],
          address[:Post_Town],
          address[:Postcode]
        ].compact
          .join(', ')

      expiry_date = Date.parse(fetch(body, :Inspection_Date)).next_year(10).to_s

      assessor = @assessors_gateway.fetch scheme_assessor_id

      raise UseCase::FetchAssessor::AssessorNotFoundException unless assessor

      unless assessor.domestic_rd_sap_qualification == 'ACTIVE'
        raise InactiveAssessorException
      end

      assessment =
        Domain::DomesticEnergyAssessment.new(
          fetch(body, :Inspection_Date),
          fetch(body, :Registration_Date),
          fetch(body, :Dwelling_Type),
          'RdSAP',
          fetch(body, :Total_Floor_Area),
          fetch(body, :RRN),
          assessor,
          address_summary,
          fetch(body, :Energy_Rating_Current).to_i,
          fetch(body, :Energy_Rating_Potential).to_i,
          address[:Postcode],
          expiry_date,
          address[:Address_Line_1],
          address[:Address_Line_2] || '',
          address[:Address_Line_3] || '',
          '',
          address[:Post_Town],
          100,
          50,
          10,
          20,
          30,
          [
            Domain::RecommendedImprovement.new(
              fetch(body, :RRN),
              fetch(body, :Sequence),
              1,
              fetch(body, :Indicative_Cost),
              fetch(body, :Typical_Saving),
              fetch(body, :Improvement_Category),
              fetch(body, :Improvement_Type),
              fetch(body, :Energy_Performance_Rating),
              fetch(body, :Environmental_Impact_Rating),
              ''
            )
          ]
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
