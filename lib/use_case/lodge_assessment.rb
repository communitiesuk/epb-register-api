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
          fetch(body, :Inspection_Date),
          fetch(body, :Registration_Date),
          fetch(body, :Dwelling_Type),
          'RdSAP',
          fetch(body, :Total_Floor_Area),
          fetch(body, :RRN),
          assessor,
          'Blah di blah',
          fetch(body, :Energy_Rating_Current).to_i,
          fetch(body, :Energy_Rating_Potential).to_i,
          body[:RdSAP_Report][:Report_Header][:Property][:Address][:Postcode],
          '2020-01-01',
          body[:RdSAP_Report][:Report_Header][:Property][:Address][:Address_Line_1],
          body[:RdSAP_Report][:Report_Header][:Property][:Address][:Address_Line_2],
          '',
          '',
          body[:RdSAP_Report][:Report_Header][:Property][:Address][:Post_Town],
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
