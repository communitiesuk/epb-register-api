desc "Fetch latest certificate information to fill blank assessors"
task :fix_blank_assessors do
  db = ActiveRecord::Base.connection

  assessments_query = <<-SQL
    SELECT assessment_id, scheme_assessor_id
    FROM
    (
      SELECT
        asm.assessment_id,
        asm.scheme_assessor_id,
        row_number() OVER (PARTITION BY asm.scheme_assessor_id ORDER BY asm.date_registered DESC) AS row_number
      FROM assessments asm
      INNER JOIN assessors a USING (scheme_assessor_id)
      WHERE a.first_name = ''
      AND a.last_name = ''
      AND asm.type_of_assessment IN ('SAP', 'RdSAP')
    ) AS assessments_by_assessor
    WHERE row_number = 1;
  SQL

  update_query = <<-SQL
    UPDATE assessors
    SET first_name = $2
    WHERE scheme_assessor_id = $1
  SQL

  updated = 0
  skipped = 0

  result = db.exec_query(assessments_query)
  result.each do |row|
    assessment_id = row["assessment_id"]
    scheme_assessor_id = row["scheme_assessor_id"]

    xml_data = ApiFactory.assessments_xml_gateway.fetch(assessment_id)

    wrapper = ViewModel::Factory.new.create(
      xml_data[:xml],
      xml_data[:schema_type],
      assessment_id,
    )
    assessor_name = wrapper.get_view_model.assessor_name

    if scheme_assessor_id.empty? or assessor_name.empty?
      skipped += 1
      next
    end

    binds = []
    binds << ActiveRecord::Relation::QueryAttribute.new("scheme_assessor_id", scheme_assessor_id, ActiveRecord::Type::String.new)
    binds << ActiveRecord::Relation::QueryAttribute.new("first_name", assessor_name, ActiveRecord::Type::String.new)

    db.exec_query(update_query, "SQL", binds)
    updated += 1
  end

  puts "fix_blank_assessors completed with #{updated} records updated and #{skipped} records skipped."
end
