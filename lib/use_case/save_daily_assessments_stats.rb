module UseCase
  class SaveDailyAssessmentsStats
    def initialize(assessment_statistics_gateway:, assessments_gateway:, assessments_xml_gateway:)
      @assessment_statistics_gateway = assessment_statistics_gateway
      @assessments_gateway = assessments_gateway
      @assessments_xml_gateway = assessments_xml_gateway
    end

    def execute(date:, assessment_types: nil)
      assessments = @assessments_gateway.fetch_assessments_by_date(date: date, assessment_types: assessment_types).map(&:symbolize_keys)

      raise Boundary::NoData, date if assessments.empty?

      assessments.each do |assessment|
        stats = stats_from_xml(assessment[:assessment_id])

        assessment.merge!(stats) unless stats.nil?
      end

      format_stats_data(assessments: assessments).each do |stat|
        @assessment_statistics_gateway.save(
          day_date: date,
          assessment_type: stat[:assessment_type],
          transaction_type: stat[:transaction_type],
          assessments_count: stat[:assessments_count],
          rating_average: stat[:rating_average],
        )
      rescue ActiveRecord::RecordNotUnique
        raise Boundary::NoData
      end
    end

  private

    def format_stats_data(assessments:)
      result = []

      group_by_type_and_transaction(assessments).each do |assessment_type, transaction_types|
        transaction_types.each do |transaction_type, assessments_with_type|
          hash = {
            assessment_type: assessment_type,
            transaction_type: transaction_type,
            assessments_count: assessments_with_type.size,
            rating_average: average_rating(assessments_with_type),
          }

          result << hash
        end
      end

      result
    end

    def average_rating(assessments)
      ratings = assessments.map { |assessment| assessment[:current_energy_efficiency_rating] }
      return nil if ratings.include?(nil)

      ratings.sum / assessments.size
    end

    def stats_from_xml(assessment_id)
      xml_data = @assessments_xml_gateway.fetch(assessment_id).symbolize_keys
      wrapper = ViewModel::Factory.new.create(xml_data[:xml].to_s, xml_data[:schema_type])
      Presenter::Export::Statistics.new(wrapper).build
    end

    def group_by_type_and_transaction(assessments)
      assessments.group_by { |assessment| assessment[:type_of_assessment] }.transform_values do |assessments_for_assessment_type|
        assessments_for_assessment_type.group_by { |assessment| assessment[:transaction_type] }
      end
    end
  end
end
