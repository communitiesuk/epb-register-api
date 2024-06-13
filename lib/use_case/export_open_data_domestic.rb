module UseCase
  class ExportOpenDataDomestic < ExportOpenDataDomesticBase
    def execute(date_from, task_id = 0, date_to = Time.now.utc)
      new_task_id = @log_gateway.fetch_new_task_id(task_id)

      assessments =
        @gateway.assessments_for_open_data(
          date_from,
          ASSESSMENT_TYPE,
          new_task_id,
          date_to,
        )

      fetch_and_format_data(assessments, new_task_id)
    end
  end
end
