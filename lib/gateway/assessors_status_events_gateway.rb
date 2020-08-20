module Gateway
  class AssessorsStatusEventsGateway
    class AssessorsStatusEvents < ActiveRecord::Base; end
    def get(date)
      sql =
        'SELECT
           assessor, scheme_assessor_id, qualification_type, previous_status, new_status
         FROM
           assessors_status_events
         WHERE
           recorded_at BETWEEN ' +
        ActiveRecord::Base.connection.quote(date.to_s) + " AND " +
        ActiveRecord::Base.connection.quote((date + 1).to_s)

      response = AssessorsStatusEvents.connection.execute(sql)

      result = []
      response.each do |row|
        assessor = JSON.parse(row["assessor"])
        result <<
          {
            first_name: assessor["first_name"],
            last_name: assessor["last_name"],
            middle_names: assessor["middle_name"],
            scheme_assessor_id: row["scheme_assessor_id"],
            date_of_birth: assessor["date_of_birth"],
            qualification_change: {
              qualification_type: row["qualification_type"],
              previous_status: row["previous_status"],
              new_status: row["new_status"],
            },
          }
      end

      result
    end

    def add(
      assessor, qualification_type, previous_status, new_status, auth_client_id
    )
      assessor = assessor.to_hash
      AssessorsStatusEvents.create(
        assessor: {
          first_name: assessor[:first_name],
          middle_names: assessor[:middle_names],
          last_name: assessor[:last_name],
          date_of_birth: assessor[:date_of_birth],
        },
        scheme_assessor_id: assessor[:scheme_assessor_id],
        qualification_type: qualification_type,
        previous_status: previous_status,
        new_status: new_status,
        recorded_at: Time.now,
        auth_client_id: auth_client_id,
      )
    end
  end
end
