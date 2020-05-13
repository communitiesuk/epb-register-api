describe UseCase::FetchAssessment do
  let(:domestic_energy_assessment_gateway) do
    AssessmentsGatewayFake.new
  end

  let(:assessors_gateway) { AssessorGatewayStub.new }

  let(:fetch_domestic_energy_assessment) do
    described_class.new(domestic_energy_assessment_gateway, assessors_gateway)
  end

  context "when there are no energy assessments" do
    it "raises a not found exception" do
      expect {
        fetch_domestic_energy_assessment.execute("123-456")
      }.to raise_exception(
        described_class::NotFoundException,
      )
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
  end
end
