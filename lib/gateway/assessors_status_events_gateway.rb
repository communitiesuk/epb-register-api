module Gateway
  class AssessorsStatusEventsGateway
    class AssessorsStatusEvents < ActiveRecord::Base; end
    def get(_date)
      sql =
        "SELECT assessor, scheme_assessor_id, qualification_type, previous_status, new_status, recorded_at FROM assessors_status_events"

      response = AssessorsStatusEvents.connection.execute(sql)

      result = []
      response.each { |_row| result << {} }

      result
    end

    def add(assessor, qualification_type, previous_status, new_status)
      assessor = assessor.to_hash
      AssessorsStatusEvents.create(
        assessor: {
          first_name: assessor[:first_name],
          middle_names: assessor[:middle_names],
          last_name: assessor[:last_name],
        },
        scheme_assessor_id: assessor[:scheme_assessor_id],
        qualification_type: qualification_type,
        previous_status: previous_status,
        new_status: new_status,
        recorded_at: Time.now,
      )
    end
  end
end
