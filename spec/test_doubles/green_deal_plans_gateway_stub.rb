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
    sql =
      "INSERT INTO
              green_deal_assessments
              (
                green_deal_plan_id,
                assessment_id
              )
              VALUES (
                  'ABC123456DEF',
                  '#{
        assessment_id
      }'
              )"
    ActiveRecord::Base.connection.execute(sql)

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
        { fuelCode: "LPG", fuelSaving: 0, standingChargeFraction: -0.3 },
      ],
    )
  end
end
