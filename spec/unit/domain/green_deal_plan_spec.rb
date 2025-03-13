describe Domain::GreenDealPlan do
  let(:arguments) do
    { green_deal_plan_id: "ABC654321DEF",
      start_date: Time.new(2020, 0o1, 30).utc.to_date,
      end_date: Time.new(2030, 0o2, 28).utc.to_date,
      provider_name: "The Bank",
      provider_telephone: "0800 0000000",
      provider_email: "lender@example.com",
      interest_rate: 12.3,
      fixed_interest_rate: true,
      charge_uplift_amount: 1.25,
      charge_uplift_date: Time.new(2025, 0o3, 29).utc.to_date,
      cca_regulated: true,
      structure_changed: false,
      measures_removed: false,
      charges: [{ end_date: "2030-03-29",
                  sequence: 0,
                  start_date: "2020-03-29",
                  daily_charge: 0.34 }],
      measures: [{ product: "WarmHome lagging stuff (TM)",
                   sequence: 0,
                   repaid_date: "2025-03-29",
                   measure_type: "Loft insulation" }],
      savings: [{ fuel_code: "39",
                  fuel_saving: 23_253,
                  standing_charge_fraction: 0 },
                { fuel_code: "40",
                  fuel_saving: -6331,
                  standing_charge_fraction: -0.9 },
                { fuel_code: "41",
                  fuel_saving: -15_561,
                  standing_charge_fraction: 0 }],
      estimated_savings: 1566 }
  end

  let(:expected_data) do
    { green_deal_plan_id: "ABC654321DEF",
      start_date: "2020-01-30",
      end_date: "2030-02-28",
      provider_details: { name: "The Bank",
                          telephone: "0800 0000000",
                          email: "lender@example.com" },
      interest: { rate: 12.3,
                  fixed: true },
      charge_uplift: { amount: 1.25,
                       date: "2025-03-29" },
      cca_regulated: true,
      structure_changed: false,
      measures_removed: false,
      measures: [{ product: "WarmHome lagging stuff (TM)",
                   sequence: 0,
                   repaid_date: "2025-03-29",
                   measure_type: "Loft insulation" }],
      charges: [{ end_date: "2030-03-29",
                  sequence: 0,
                  start_date: "2020-03-29",
                  daily_charge: 0.34 }],
      savings: [{ fuel_code: "39",
                  fuel_saving: 23_253,
                  standing_charge_fraction: 0 },
                { fuel_code: "40",
                  fuel_saving: -6331,
                  standing_charge_fraction: -0.9 },
                { fuel_code: "41",
                  fuel_saving: -15_561,
                  standing_charge_fraction: 0 }],
      estimated_savings: 1566 }
  end

  let(:domain) { described_class.new(**arguments) }

  it "returns a domain object" do
    expect(domain).to be_an_instance_of described_class
  end

  describe "#to_hash" do
    it "returns the expected data" do
      expect(domain.to_hash).to eq(expected_data)
    end
  end
end
