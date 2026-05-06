module Gateway
  class AssessorsStatusEventsGateway
    SCOTTISH_QUALIFICATIONS = %w[scotland_dec_and_ar
                                 scotland_nondomestic_existing_building
                                 scotland_nondomestic_new_building
                                 scotland_rdsap
                                 scotland_sap_existing_building
                                 scotland_sap_new_building
                                 scotland_section63].freeze
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

    def get_scottish_assessor_events(start_date:, end_date:, current_page:, limit: 5000)
      sql = <<~SQL
        SELECT
          ase.assessor, ase.scheme_assessor_id, ase.qualification_type, ase.previous_status, ase.new_status, ase.recorded_at
        FROM
          assessors_status_events ase
        WHERE
          recorded_at BETWEEN $1 AND $2
        AND
          ase.qualification_type IN (#{scottish_qualifications})
        ORDER BY recorded_at
        LIMIT $3
        OFFSET $4;
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "start_date",
          start_date.to_s,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "end_date",
          end_date.to_s,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "limit",
          limit,
          ActiveRecord::Type::Integer.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "offset",
          Helper::PaginationHelper.calculate_offset(current_page, limit),
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
            recorded_at: row["recorded_at"],
          ).to_hash_scotland
      end

      result
    end

    def count_scottish_assessor_events(start_date:, end_date:)
      sql = <<~SQL
        SELECT
          COUNT(*)
        FROM
          assessors_status_events ase
        WHERE
          recorded_at BETWEEN $1 AND $2
        AND
          ase.qualification_type IN (#{scottish_qualifications});
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "start_date",
          start_date.to_s,
          ActiveRecord::Type::String.new,
        ),
        ActiveRecord::Relation::QueryAttribute.new(
          "end_date",
          end_date.to_s,
          ActiveRecord::Type::String.new,
        ),
      ]

      AssessorsStatusEvents.connection.exec_query(sql, "SQL", binds).first["count"]
    end

    def add(assessor_status_event_domain)
      AssessorsStatusEvents.create(assessor_status_event_domain.to_record)
    end

  private

    def scottish_qualifications
      SCOTTISH_QUALIFICATIONS.map { |n| "'#{n}'" }.join(",")
    end
  end
end
