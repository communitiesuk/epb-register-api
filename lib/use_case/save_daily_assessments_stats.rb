module UseCase
  class SaveDailyAssessmentsStats
    class NoDataException < StandardError; end

    def initialize(assessment_statistics_gateway:, assessments_gateway:, assessments_xml_gateway:)
      @assessment_statistics_gateway = assessment_statistics_gateway
      @assessments_gateway = assessments_gateway
      @assessments_xml_gateway = assessments_xml_gateway
    end

    def execute(date:, assessment_types: nil)
      @assessments = @assessments_gateway.fetch_assessments_by_date(date: date, assessment_types: assessment_types)

      raise NoDataException, "No assessments for #{date}" if @assessments.empty?

      @assessments.each do |assessment|
        stats = stats_from_xml(assessment["assessment_id"])

        assessment.merge!(stats) unless stats.nil?
      end

      format_stats_data
    end

  private

    def format_stats_data
      result = []

      grouped_by_type_scheme_transaction_type.each do |assessment_type, schemes|
        schemes.each do |scheme_id, transaction_types|
          transaction_types.each do |transaction_type, assessments|
            hash = {
              assessment_type: assessment_type,
              scheme_id: scheme_id,
              transaction_type: transaction_type,
              assessments_count: assessments.size,
              rating_average: average_rating(assessments),
            }

            result << hash
          end
        end
      end

      result
    end

    def average_rating(assessments)
      ratings = assessments.map { |assessment| assessment[:current_energy_rating] }
      return nil if ratings.include?(nil)

      ratings.sum / assessments.size
    end

    def stats_from_xml(assessment_id)
      xml_data = @assessments_xml_gateway.fetch(assessment_id)
      wrapper = ViewModel::Factory.new.create(xml_data["xml"].to_s, xml_data["schema_type"])
      Presenter::Export::Statistics.new(wrapper).build
    end

    def grouped_by_type_scheme_transaction_type
      @assessments.group_by { |assessment| assessment["assessment_type"] }.transform_values do |assessments_for_assessment_type|
        assessments_for_assessment_type.group_by { |assessment| assessment[:scheme_id] }.transform_values do |assessments_for_scheme|
          assessments_for_scheme.group_by { |assessment| assessment[:transaction_type] }
        end
      end
    end
  end
end
