module UseCase
  class FetchAssessmentIdForCountryIdBackfill
    def initialize(assessments_gateway:)
      @assessments_gateway = assessments_gateway
    end

    def execute(date_from:, date_to:, assessment_types: nil)
      raise Boundary::InvalidDates if Time.parse(date_to) < Time.parse(date_from)

      assessment_ids = if assessment_types.nil?
                         @assessments_gateway.fetch_assessment_id_by_date_and_type(date_from:, date_to:)
                       else
                         @assessments_gateway.fetch_assessment_id_by_date_and_type(date_from:, date_to:, assessment_types:)
                       end

      raise Boundary::NoAssessments, " dates: #{date_from} - #{date_to} and assessment_types: #{assessment_types}" if assessment_ids.empty?

      assessment_ids
    end
  end
end
