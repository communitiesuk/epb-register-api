class GreenDealPlansGatewayStub
  attr_reader :green_deal_plan

  def initialize(assessment_id = nil)
    @assessment_id = assessment_id
  end

  def fetch(assessment_id)
    return create_green_deal_plan("6969-6969") if assessment_id == "6969-6969"

    nil
  end

  def create_green_deal_plan(assessment_id)
    GreenDealPlans.create(
      green_deal_plan_id: "ABC123456DEF",
      start_date: DateTime.new(2_020, 1, 30),
      end_date: DateTime.new(2_030, 2, 28),
      provider_name: "The Bank",
      provider_telephone: "0800 0000000",
      provider_email: "lender@example.com",
      fixed_interest_rate: true,
      charge_uplift_date: DateTime.new(2_030, 2, 28),
      measures: [
        {
          measureType: "Loft insulation",
          product: "WarmHome lagging stuff (TM)",
          repaidDate: "2025-03-29",
        },
      ],
      charges: [
        { startDate: "2020-03-29", endDate: "2030-03-29", dailyCharge: "0.34" },
      ],
      savings: [
        { fuel_code: "39", fuel_saving: 23_253, standing_charge_fraction: 0 },
        { fuel_code: "40", fuel_saving: -6331, standing_charge_fraction: -0.9 },
        { fuel_code: "41", fuel_saving: -15_561, standing_charge_fraction: 0 },
      ],
    )

    sql =
      "INSERT INTO
              green_deal_assessments
              (
                green_deal_plan_id,
                assessment_id
              )
              VALUES (
                  'ABC123456DEF',
                  '#{assessment_id}'
              )"
    ActiveRecord::Base.connection.exec_query(sql)
  end
end
