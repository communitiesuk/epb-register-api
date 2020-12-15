require "nokogiri"

module UseCase
  class OpenDataExport
    def initialize; end

    def execute(args = {})
      type_of_assessment = args[:type_of_assessment]
      schema_type = args[:schema_type]
      from_date = args[:from_date]
      to_date = args[:to_date]
      number_of_assessments = args[:number_of_assessments]
      batch = args[:batch]
      max_runs = args[:max_runs]

      # puts "Starting extraction at #{Time.now}"

      where =
        "a.opt_out = false AND a.cancelled_at IS NULL AND a.not_for_issue_at IS NULL"

      if type_of_assessment
        where <<
          " AND a.type_of_assessment = " +
          ActiveRecord::Base.connection.quote(type_of_assessment)
      end

      if schema_type
        where <<
          " AND b.schema_type = " +
          ActiveRecord::Base.connection.quote(schema_type)
      end

      if from_date && to_date
        where <<
          " AND a.date_registered BETWEEN " +
          ActiveRecord::Base.connection.quote(from_date) + " AND " +
          ActiveRecord::Base.connection.quote(to_date)
      end

      # number_of_assessments = ActiveRecord::Base.connection.execute("SELECT COUNT(assessment_id) AS number_of_assessments FROM assessments a WHERE #{where}").first["number_of_assessments"]

      # puts "Done getting number of assessments. #{number_of_assessments} in total at #{Time.now}"

      start = 0
      results = []
      while start <= number_of_assessments.to_i
        assessments =
          ActiveRecord::Base.connection.execute(
            "
      SELECT
        a.assessment_id, b.xml, b.schema_type, c.address_id
      FROM
        assessments a
      LEFT JOIN
        assessments_xml b
      ON(a.assessment_id = b.assessment_id)
      LEFT JOIN
        assessments_address_id c
      ON(a.assessment_id = c.assessment_id)
      WHERE
        #{where}
      ORDER BY
        a.date_registered
      LIMIT
        " + batch +
              '
      OFFSET
        ' + start.to_s +
              '
        ',
          )
        # puts "Done getting batch #{start} from DB at #{Time.now}"

        data = []

        assessments.each do |assessment|
          report_model =
            ViewModel::Factory.new.create(
              assessment["xml"],
              assessment["schema_type"],
              assessment["assessment_id"],
            )

          hash = report_model.to_hash

          data.push(
            {
              REPORT_TYPE: hash[:type_of_assessment],
              RRN: hash[:assessment_id],
              INSPECTION_DATE: hash[:date_of_assessment],
              LODGEMENT_DATE: hash[:date_of_registration],
              BUILDING_REFERENCE_NUMBER: assessment["address_id"],
              ADDRESS1: hash[:address][:address_line1],
              ADDRESS2: hash[:address][:address_line2],
              ADDRESS3: hash[:address][:address_line3],
              ADDRESS4: hash[:address][:address_line4],
              POSTTOWN: hash[:address][:town],
              POSTCODE: hash[:address][:postcode],
            },
          )
        end

        # puts "Done preparing array for CSV at #{Time.now}"

        results <<
          CSV.generate(
            write_headers: (start == 0),
            headers: data.first ? data.first.keys : [],
          ) { |csv| data.each { |row| csv << row } }

        start += batch.to_i

        if max_runs && max_runs.to_i <= start
          # puts "Exiting as max runs was reached"
          break
        end
      end
      results
    end
  end
end
