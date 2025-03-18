module Domain
  class RelatedAssessments
    def initialize(
      assessment_id:,
      type_of_assessment:,
      assessments:
    )
      @assessment_id = assessment_id
      @type_of_assessment = type_of_assessment
      @assessments = assessments
      @filtered_by_types = nil
      @superseded_by = nil

      filter_by_types
      find_superseded_by
      filter_self_or_opt_out
    end

    attr_reader :assessments, :superseded_by

  private

    def filter_by_types
      domestic_types = %w[RdSAP SAP]

      @filtered_by_types = assessments.filter do |assessment|
        related = assessment.to_hash

        (
          domestic_types.include?(related[:assessment_type]) &&
            domestic_types.include?(@type_of_assessment)
        ) || related[:assessment_type] == @type_of_assessment
      end
    end

    def find_superseded_by
      @superseded_by = @filtered_by_types.length.positive? && @filtered_by_types.first.to_hash[:assessment_id] != @assessment_id ? @filtered_by_types.first.to_hash[:assessment_id] : nil
    end

    def filter_self_or_opt_out
      @assessments = @filtered_by_types.filter do |assessment|
        related = assessment.to_hash
        related[:assessment_id] != @assessment_id && related[:opt_out] == false
      end
    end
  end
end
