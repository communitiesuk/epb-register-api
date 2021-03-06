desc "Backfill linked assessments table from assessments XML"

task :linked_assessments do
  require "nokogiri"
  require "zeitwerk"

  loader = Zeitwerk::Loader.new
  loader.push_dir("#{__dir__}/../")
  loader.setup

  if ENV["from_date"].nil?
    abort("Please set the from_date environment variable")
  end

  puts "[#{Time.now}] Starting processing linked assessment"

  find_assessments_sql = <<-SQL
    SELECT a.assessment_id
    FROM assessments a
    LEFT JOIN linked_assessments la USING (assessment_id)
    WHERE a.date_registered >= #{ActiveRecord::Base.connection.quote(ENV['from_date'])}
    AND la.assessment_id IS NULL
  SQL

  assessment_types = []
  %w[DEC DEC-RR CEPC CEPC-RR AC-REPORT AC-CERT].each do |type|
    assessment_types.push(ActiveRecord::Base.connection.quote(type))
  end
  find_assessments_sql += " AND a.type_of_assessment IN(" + assessment_types.join(", ") + ")"

  assessments = ActiveRecord::Base.connection.exec_query find_assessments_sql
  puts "[#{Time.now}] Found #{assessments.length} assessments to process"

  inserted = 0
  skipped = 0
  assessments.each do |assessment|
    assessment_id = assessment["assessment_id"]
    assessment_xml = ActiveRecord::Base.connection.exec_query("SELECT xml, schema_type FROM assessments_xml WHERE assessment_id = '#{assessment_id}'").first
    if assessment_xml.nil?
      puts "[#{Time.now}] Could not read XML for assessment #{assessment_id}"
      skipped += 1
    else
      report_model = ViewModel::Factory.new.create(assessment_xml["xml"], assessment_xml["schema_type"], assessment_id)
      related_rrn = find_related_rrn(report_model.to_hash)

      if related_rrn.nil?
        skipped += 1
      else
        ActiveRecord::Base.connection.exec_query("INSERT INTO linked_assessments VALUES('#{assessment_id}','#{related_rrn}')")
        inserted += 1
      end
    end
  end
  puts "[#{Time.now}] Finished processing linked assessment, skipped:#{skipped} inserted:#{inserted}"
end

def find_related_rrn(wrapper_hash)
  related_rrn = nil
  # related-rrn: AC-CERT AC-REPORT CEPC DEC-RR
  related_rrn = wrapper_hash[:related_rrn] unless wrapper_hash[:related_rrn].nil?
  # related_certificate: CEPC-RR
  related_rrn = wrapper_hash[:related_certificate] unless wrapper_hash[:related_certificate].nil?
  # administrative_information->related_rrn: DEC
  if related_rrn.nil? && !wrapper_hash.dig(:administrative_information, :related_rrn).nil?
    related_rrn = wrapper_hash[:administrative_information][:related_rrn]
  end
  related_rrn
end
