module UseCase
  class SaveDailyAssessmentsStats
    def initialize(assessment_statistics_gateway:, assessments_gateway:, assessments_xml_gateway:)
      @assessment_statistics_gateway = assessment_statistics_gateway
      @assessments_gateway = assessments_gateway
      @assessments_xml_gateway = assessments_xml_gateway
    end

    def execute(date:)
      @assessments = @assessments_gateway.fetch_assessments_by_date(date)
      @assessments.each do |assessment|
        assessment.merge!(stats_from_xml(assessment["assessment_id"]))
      end

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
          hash[:rating_average] = average_rating(assessments)

          result << hash
        end
      end

      result
    end

    def average_rating(assessments)
      assessments.map { |assessment| assessment[:current_energy_rating] }.sum / assessments.size
    end

    def stats_from_xml(assessment_id)
      # TODO
      # xml_data = @assessments_xml_gateway.fetch(assessment_id)
      # wrapper = ViewModel::Factory.new.create(xml_data["xml"].to_s, xml_data["schema_type"])
      # Presenter::Export::Statistics.new(wrapper).build
    end

    def grouped_by_type_and_scheme
      @assessments.group_by { |assessment| assessment["assessment_type"] }.transform_values do |x|
        x.group_by { |y| y[:scheme_id] }
      end
    end
  end
end
