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
      class AssessmentsDomainFake
        def initialize(data)
          @data = data
          @data[:potential_energy_efficiency_band] = "c"
          @data[:current_energy_efficiency_band] = "c"
          @data.delete(:scheme_assessor_id)
          @data[:assessor] = {}
        end

        def scheme_assessor_id; end

        def to_hash
          @data
        end

        def set(key, value)
          instance_variable_set "@#{key}", value
        end

        def get(key)
          instance_variable_get "@#{key}"
        end
      end

      domestic_energy_assessment_gateway.domestic_energy_assessment =
        AssessmentsDomainFake.new(
          current_energy_efficiency_rating: 75,
          potential_energy_efficiency_rating: 80,
          scheme_assessor_id: 0,
        )
      result = fetch_domestic_energy_assessment.execute("123-456")
      expect(result.to_hash).to eq(
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
