describe UseCase::FetchRenewableHeatIncentive do
  let(:renewable_heat_incentive_gateway_fake) do
    RenewableHeatIncentiveGatewayFake.new
  end

  let(:fetch_renewable_heat_incentive) do
    described_class.new(renewable_heat_incentive_gateway_fake)
  end

  context "when there are no renewable heat incentives" do
    it "raises a not found exception" do
      expect {
        fetch_renewable_heat_incentive.execute("246-890")
      }.to raise_exception(described_class::NotFoundException)
    end
  end

  context "when there is an energy assessment" do
    it "returns the renewable heat incentive data ONLY" do
      result = fetch_renewable_heat_incentive.execute("123-456")
      expect(result).to eq(
        {
          epcRrn: "0000-0000-0000-0000-0000",
          assessorName: "Jo Bloggs",
          reportType: "Energy Performance Certificate",
          inspectionDate: "2020-01-30",
          lodgementDate: "2020-02-29",
          dwellingType: "Top-floor flat",
          postcode: "SW1P 4JA",
          propertyAgeBand: "D",
          tenure: "Owner-occupied",
          totalFloorArea: "123.5 square metres",
          cavityWallInsulation: false,
          loftInsulation: true,
          spaceHeating: "Gas-fired central heating",
          waterHeating: "Electrical immersion heater",
          secondaryHeating: "Electric bar heater",
          energyEfficiency: {
            currentRating: 64,
            currentBand: "c",
            potentialRating: 75,
            potentialBand: "d",
          },
        },
      )
    end
  end
end
