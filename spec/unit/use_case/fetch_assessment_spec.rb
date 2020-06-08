describe UseCase::FetchAssessment do
  let(:domestic_energy_assessment_gateway) { AssessmentsGatewayFake.new }

  let(:assessors_gateway) { AssessorGatewayStub.new }

  let(:green_deal_plans_gateway) { GreenDealPlansGatewayStub.new }

  let(:fetch_domestic_energy_assessment) do
    described_class.new(
      domestic_energy_assessment_gateway,
      assessors_gateway,
      green_deal_plans_gateway,
    )
  end

  context "when there are no energy assessments" do
    it "raises a not found exception" do
      expect {
        fetch_domestic_energy_assessment.execute("123-456")
      }.to raise_exception(described_class::NotFoundException)
    end
  end

  context "when there is an energy assessment" do
    it "gives the existing energy assessment" do
      domestic_energy_assessment_gateway.domestic_energy_assessment = {
        current_energy_efficiency_rating: 75,
        potential_energy_efficiency_rating: 80,
      }
      result = fetch_domestic_energy_assessment.execute("123-456")
      expect(result).to eq(
        {
          assessor: assessors_gateway.assessor,
          current_energy_efficiency_band: "c",
          potential_energy_efficiency_band: "c",
          current_energy_efficiency_rating: 75,
          potential_energy_efficiency_rating: 80,
        },
      )
    end

    context "when the energy assessment has a green deal plan" do
      it "adds the green deal plan data to the assessment" do
        domestic_energy_assessment_gateway.domestic_energy_assessment = {
          current_energy_efficiency_rating: 75,
          potential_energy_efficiency_rating: 80,
        }
        result = fetch_domestic_energy_assessment.execute("6969-6969")
        expect(result).to eq(
          {
            assessor: assessors_gateway.assessor,
            current_energy_efficiency_band: "c",
            potential_energy_efficiency_band: "c",
            current_energy_efficiency_rating: 75,
            potential_energy_efficiency_rating: 80,
            green_deal_plan: {
              greenDealPlanId: "ABC123456DEF",
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
            },
          },
        )
      end
    end
  end
end
