module UseCase
  class SendDailyStatsToSlack
    include Sidekiq::Worker
    
    ASSESSMENTS_WITH_AVERAGE_RATING = %w[SAP RdSAP CEPC].freeze

    def initialize(assessment_statistics_gateway:)
      @assessment_statistics_gateway = assessment_statistics_gateway
    end

    def execute
      yesterday = (Time.now - 1.day).strftime("%F")
      daily_stats = @assessment_statistics_gateway.fetch_daily_stats_by_date(yesterday)

      no_stats_message = "No stats for yesterday. Assessors were on hols :palm_tree: or our scheduled job didn't work :robot_face:"
      message = daily_stats.empty? ? no_stats_message : format_message(daily_stats)

      Worker::SlackNotification.perform_async(message)
    end

  private

    def format_message(daily_stats)
      total = daily_stats.map { |stat| stat["number_of_assessments"] }.sum
      total_text = "The total of *#{total}* assessments were lodged yesterday of which: \n"

      assessment_breakdown_text = daily_stats.map do |assessment|
        row = "• *#{assessment['number_of_assessments']}* #{assessment['assessment_type']}s"
        row += " with an average rating of #{assessment['rating_average'].round(1)}" if ASSESSMENTS_WITH_AVERAGE_RATING.include?(assessment["assessment_type"])
        row
      end

      total_text + assessment_breakdown_text.join("\n")
    end
  end
end
