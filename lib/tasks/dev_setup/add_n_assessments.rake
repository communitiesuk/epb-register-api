namespace :dev_data do
  desc "Lodge a certain number of assessments in one go, with stock (not fully representative) contents"
  task :add_n_assessments, %i[assessment_count] do |_, args|
    count = args.assessment_count.to_i
    if count.zero?
      puts "A non-positive assessment count was requested... exiting."
      next
    end

    use_case = ApiFactory.validate_and_lodge_assessment_use_case

    next_id = Proc.new do |assessment_id|
      next_number = BigDecimal(assessment_id.gsub(/-/, '')) + BigDecimal("1")
      next_number.truncate.to_s.rjust(20, "0").scan(/.{4}/).join("-")
    end

    cursor = ActiveRecord::Base.connection.exec_query(
      "SELECT MAX(assessment_id) AS largest FROM assessments"
    ).first["largest"]

    template = Nokogiri.XML(File.read(File.join(__dir__, "template.xml")))

    count.times do
      cursor = next_id.call cursor
      rrn_element = template.at("RRN")
      rrn_element.content = cursor
      use_case.execute assessment_xml: template.to_s,
                       schema_name: "SAP-Schema-18.0.0",
                       scheme_ids: 1.upto(17),
                       migrated: false,
                       overidden: false
    end

    puts "#{count} assessments written with final assessment ID: #{cursor}"
  end
end
