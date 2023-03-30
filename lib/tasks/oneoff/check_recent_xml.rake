require "nokogiri"

namespace :oneoff do
  desc "Check last n assessments of each type and perform strict parsing on the submitted XML"
  task :check_recent_xml, [:count_per_assessment_type] do |_, args|
    count_per_assessment_type = args[:count_per_assessment_type]
    assessment_types = ActiveRecord::Base.connection.exec_query(
      "SELECT DISTINCT type_of_assessment FROM assessments",
    ).map(&:values).flatten.sort
    puts "Checking recent assessments..."
    total_checks = 0
    total_fails = 0
    xml_sql = "SELECT xml FROM assessments_xml AS ax INNER JOIN assessments AS a ON ax.assessment_id=a.assessment_id WHERE a.type_of_assessment=$1 LIMIT #{count_per_assessment_type.to_i}"
    assessment_types.each do |assessment_type|
      ActiveRecord::Base.connection.send(:exec_no_cache, xml_sql, "SQL", [ActiveRecord::Relation::QueryAttribute.new("type_of_assessment", assessment_type, ActiveRecord::Type::String.new)]).each do |row|
        Nokogiri.XML(row.values.first, &:strict)
      rescue Nokogiri::XML::SyntaxError
        total_fails += 1
      ensure
        total_checks += 1
      end
      puts "Checked assessments with type #{assessment_type}"
    end
    puts "...done"
    puts "Total XML documents checked: #{total_checks}"
    puts "Total parse failures: #{total_fails}"
  end
end
