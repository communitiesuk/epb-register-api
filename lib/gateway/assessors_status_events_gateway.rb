module Gateway
  class AssessorsStatusEventsGateway
    class AssessorsStatusEvents < ActiveRecord::Base
    end

    def filter_by(date, scheme_id)
      sql = <<~SQL
        SELECT
           ase.assessor, ase.scheme_assessor_id, ase.qualification_type, ase.previous_status, ase.new_status
         FROM
           assessors_status_events ase
                LEFT JOIN
                 assessors a
                ON (ase.scheme_assessor_id = a.scheme_assessor_id)
                INNER JOIN
               assessors a2
                ON ( a.last_name LIKE a2.last_name||'%') AND (a.date_of_birth = a2.date_of_birth)
        WHERE recorded_at BETWEEN $1 AND $2
            AND a.registered_by != $3
            AND a2.registered_by = $3
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "from_date",
          date.to_s,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "to_date",
          (date + 1).to_s,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "scheme_id",
          scheme_id.to_i,
          ActiveRecord::Type::String.new,
        ),
      ]

      response = AssessorsStatusEvents.connection.exec_query(sql, "SQL", binds)

      result = []
      response.each do |row|
        result <<
          Domain::AssessorsStatusEvent.new(
            assessor: JSON.parse(row["assessor"]),
            scheme_assessor_id: row["scheme_assessor_id"],
            qualification_type: row["qualification_type"],
            previous_status: row["previous_status"],
            new_status: row["new_status"],
          )
      end

      result
    end

    def add(assessor_status_event_domain)
      AssessorsStatusEvents.create(assessor_status_event_domain.to_record)
    end
  end
end
