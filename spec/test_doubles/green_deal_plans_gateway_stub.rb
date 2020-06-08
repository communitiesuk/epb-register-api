class GreenDealPlansGatewayStub
  attr_reader :green_deal_plan

  def initialize(assessment_id = nil)
    @assessment_id = assessment_id
  end

  def fetch(assessment_id)
    return green_deal_plans_data if assessment_id == "6969-6969"

    nil
  end

  def green_deal_plans_data
    {
      greenDealPlanId: "ABC123456DEF",
      startDate: "2020-01-30",
      endDate: "2030-02-28",
      providerDetails: {
        name: "The Bank", telephone: "0800 0000000", email: "lender@example.com"
      },
      interest: { rate: 12.3, fixed: true },
      chargeUplift: { amount: 1.25, date: "2025-03-29" },
      ccaRegulated: true,
      structureChanged: false,
      measuresRemoved: false,
      measures: [
        {
          sequence: 0,
          measureType: "Loft insulation",
          product: "WarmHome lagging stuff (TM)",
          repaidDate: "2025-03-29",
        },
      ],
      charges: [
        {
          sequence: 0,
          startDate: "2020-03-29",
          endDate: "2030-03-29",
          dailyCharge: "0.34",
        },
      ],
      savings: [
        {
          sequence: 0,
          fuelCode: "LPG",
          fuelSaving: 0,
          standingChargeFraction: -0.3,
        },
      ],
    }
  end
end
