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
      interest: {
        rate: 12.3,
        fixed: true,
      },
      chargeUplift: {
        amount: 1.25,
        date: "2025-03-29",
      },
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
      savings_scotland: [],
      estimatedSavings: 1566,
    }
  end

  def stubbed_domain(is_scottish, green_deal_plan_id = "ABC123456DEF")
    savings = [
      { fuel_code: "39", fuel_saving: 23_253, standing_charge_fraction: 0 },
      { fuel_code: "40", fuel_saving: -6331, standing_charge_fraction: -0.9 },
      { fuel_code: "41", fuel_saving: -15_561, standing_charge_fraction: 0 },
    ]
    savings_scotland = [
      {
        savings_electricity_yearly: 0.0382,
        savings_gas_yearly: 0.0338,
        savings_other_yearly: 0.0,
        savings_total_yearly: 0.072,
      },
    ]
    Domain::GreenDealPlan.new(
      green_deal_plan_id: green_deal_plan_id,
      start_date: "2020-01-30",
      end_date: "2030-02-28",
      provider_name: "The Bank",
      provider_email: "lender@example.com",
      provider_telephone: "0800 0000000",
      cca_regulated: true,
      structure_changed: false,
      measures_removed: false,
      charge_uplift_amount: 1.25,
      charge_uplift_date: "2025-03-29",
      interest_rate: 12.3,
      fixed_interest_rate: true,
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
      savings: is_scottish ? [] : savings,
      savings_scotland: is_scottish ? savings_scotland : [],
    )
  end
end
