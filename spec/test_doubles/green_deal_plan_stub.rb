class GreenDealPlanStub
  def request_body(green_deal_plan_id = "ABC123456DEF")
    {
      greenDealPlanId: green_deal_plan_id,
      startDate: "2020-01-30",
      endDate: "2030-02-28",
      providerDetails: {
        name: "The Bank",
        telephone: "0800 0000000",
        email: "lender@example.com",
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
          dailyCharge: 0.34,
        },
      ],
      savings: [
        { fuelCode: "39", fuelSaving: 23_253, standingChargeFraction: 0 },
        { fuelCode: "40", fuelSaving: -6331, standingChargeFraction: -0.9 },
        { fuelCode: "41", fuelSaving: -15_561, standingChargeFraction: 0 },
      ],
      estimatedSavings: 1566,
    }
  end
end
