module UseCase
  class UpdateAssessmentsFromLandmark
    def initialize(assessments_gateway:, storage_gateway:)
      @assessments_gateway = assessments_gateway
      @storage_gateway = storage_gateway
    end

    def execute(file_name:)
      file_io = @storage_gateway.get_file_io(file_name)
      csv = CSV.new(file_io, headers: true)
      num_updated = 0
      while (row = csv.shift)
        rrn = row["REPORT_REFERENCE_ID"]
        date = row["LODGEMENT_DATE"]
        result = @assessments_gateway.update_created_at_from_landmark?(rrn, date)
        num_updated += 1 if result
      end
      num_updated
    end
  end
end
