module Gateway
  class ExportNiGateway
    def fetch_assessments(type_of_assessment)
      sql = <<-SQL
      SELECT
      a.assessment_id
      FROM assessments a
      INNER JOIN assessments_xml ax USING(assessment_id)
      WHERE  a.postcode LIKE 'BT%' AND
        ax.schema_type LIKE '%NI%'
      SQL

      # TOD0 extract this to helper method
      if type_of_assessment.is_a?(Array)
        valid_type = %w[RdSAP SAP]
        invalid_types = type_of_assessment - valid_type
        raise StandardError, "Invalid types" unless invalid_types.empty?

        list_of_types = type_of_assessment.map { |n| "'#{n}'" }
        sql << <<~SQL_TYPE_OF_ASSESSMENT
          AND type_of_assessment IN(#{list_of_types.join(',')})
        SQL_TYPE_OF_ASSESSMENT
      else
        valid_types = %w[CEPC DEC]
        unless valid_types.include? type_of_assessment
          raise StandardError, "Invalid types"
        end

        sql << <<~SQL_TYPE_OF_ASSESSMENT
          AND type_of_assessment = '#{type_of_assessment}'
        SQL_TYPE_OF_ASSESSMENT
      end

      results = ActiveRecord::Base.connection.exec_query(sql)

      results.map { |result| result }
    end
  end
end
