module Domain
  class RecommendedImprovement
    attr_reader :sequence

    def initialize(
      assessment_id,
      sequence,
      improvement_code,
      indicative_cost,
      typical_saving,
      improvement_category,
      improvement_type,
      energy_performance_rating_improvement,
      environmental_impact_rating_improvement,
      green_deal_category_code
    )
      @assessment_id = assessment_id
      @sequence = sequence
      @improvement_code = improvement_code
      @indicative_cost = indicative_cost
      @typical_saving = typical_saving
      @improvement_category = improvement_category
      @improvement_type = improvement_type
      @energy_performance_rating_improvement =
        energy_performance_rating_improvement
      @environmental_impact_rating_improvement =
        environmental_impact_rating_improvement
      @green_deal_category_code = green_deal_category_code
    end

    def to_hash
      {
        sequence: @sequence,
        improvement_code: @improvement_code,
        indicative_cost: @indicative_cost,
        typical_saving: @typical_saving,
        improvement_category: @improvement_category,
        improvement_type: @improvement_type,
        energy_performance_rating_improvement:
          @energy_performance_rating_improvement,
        environmental_impact_rating_improvement:
          @environmental_impact_rating_improvement,
        green_deal_category_code: @green_deal_category_code
      }
    end

    def to_record
      {
        sequence: @sequence,
        assessment_id: @assessment_id,
        improvement_code: @improvement_code,
        indicative_cost: @indicative_cost,
        typical_saving: @typical_saving,
        improvement_category: @improvement_category,
        improvement_type: @improvement_type,
        energy_performance_rating_improvement:
          @energy_performance_rating_improvement,
        environmental_impact_rating_improvement:
          @environmental_impact_rating_improvement,
        green_deal_category_code: @green_deal_category_code
      }
    end
  end
end
