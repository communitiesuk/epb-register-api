module UseCase
  class SaveDailyAssessmentsStats
    def initialize(assessment_statistics_gateway:, assessments_gateway:)
      @assessment_statistics_gateway = assessment_statistics_gateway
      @assessments_gateway = assessments_gateway
    end

    def execute(date:)
      @assessments = @assessments_gateway.fetch_assessments_by_date(date)

      format_stats_data
    end

  private

    def format_stats_data
      result = []
      grouped_by_type_and_scheme.each do |assessment_type, scheme_assessments|
        scheme_assessments.each do |scheme_id, assessments|
          hash = {}
          hash[:assessment_type] = assessment_type
          hash[:scheme_id] = scheme_id
          hash[:assessments_count] = assessments.size
          # TODO: get it from the XML
          hash[:rating_average] = assessments.map { |a| a[:current_energy_rating] }.sum / assessments.size
          result << hash
        end
      end

      result
    end

    def grouped_by_type_and_scheme
      @assessments.group_by { |assessment| assessment["assessment_type"] }.transform_values do |x|
        x.group_by { |y| y[:scheme_id] }
      end
    end
  end
end
