require "nokogiri"

module UseCase
  class ExportOpenDataDomesticByHashedId < ExportOpenDataDomesticBase
    def execute(hashed_assessment_ids, task_id = 0)
      new_task_id = @log_gateway.fetch_new_task_id(task_id)

      assessments =
        @gateway.assessments_for_open_data_by_hashed_assessment_id(
          hashed_assessment_ids,
          ASSESSMENT_TYPE,
          new_task_id,
        )

      fetch_and_format_data(assessments, new_task_id)
    end
  end
end
