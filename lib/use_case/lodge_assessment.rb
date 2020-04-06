# frozen_string_literal: true

module UseCase
  class LodgeAssessment
    def initialize(domestic_energy_assessments_gateway, assessors_gateway)
      @domestic_energy_assessments_gateway = domestic_energy_assessments_gateway
      @assessors_gateway = assessors_gateway
    end

    def execute(body, _assessment_id, _content_type)
      assessor =
        @assessors_gateway.fetch(
          body[:RdSAP_Report][:Report_Header][:Energy_Assessor][
            :Identification_Number
          ][
            :Membership_Number
          ]
        )

      assessment =
        Domain::DomesticEnergyAssessment.new(
          '2019-01-01',
          '2019-01-01',
          body[:RdSAP_Report][:Energy_Assessment][:Property_Summary][
            :Dwelling_Type
          ],
          'RdSAP',
          '500',
          body[:RdSAP_Report][:Report_Header][:RRN],
          assessor,
          'Blah di blah',
          99,
          99,
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
  end
end
