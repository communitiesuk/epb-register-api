namespace :dev_data do
  desc "Lodge assessments to the dev database for testing"
  task :lodge_dev_assessments do
    Tasks::TaskHelpers.quit_if_production
    DevAssessmentsHelper.lodge_assessments(DevAssessmentsHelper.read_fixtures)
  end
end

class DevAssessmentsHelper
  def self.schema_array
    %w[CEPC-8.0.0 CEPC-NI-8.0.0 RdSAP-Schema-20.0.0 RdSAP-Schema-NI-20.0.0 SAP-Schema-18.0.0 SAP-Schema-NI-18.0.0 SAP-Schema-16.3 SAP-Schema-13.0 SAP-Schema-10.2]
  end

  def self.split_sap_versions
    %w[SAP-Schema-16.3 SAP-Schema-13.0]
  end

  def self.commercial_fixtures
    %w[ac-cert+ac-report cepc+rr dec+rr]
  end

  def self.read_xml(schema, type = "epc")
    path = File.join Dir.pwd, "spec/fixtures/dev_data/#{schema}/#{type}.xml"

    unless File.exist? path
      raise ArgumentError,
            "No #{type} sample found for schema #{schema}, create one at #{
              path
            }"
    end
    File.read path
  end

  def self.read_fixtures
    file_array = []
    schema_array.each do |schema|
      if schema.include?("CEPC")
        next
      elsif schema == "SAP-Schema-10.2"
        file_content = read_xml(schema, "rdsap")
      elsif split_sap_versions.include?(schema)
        file_content = read_xml(schema, "rdsap")
        file_array << { xml: Nokogiri.XML(file_content), schema: }
        file_content = read_xml(schema, "sap")
      else
        file_content = read_xml(schema, "epc")
      end

      file_array << { xml: Nokogiri.XML(file_content), schema: }
    end
    file_array + read_commercial_fixtures
  end

  def self.read_commercial_fixtures
    file_array = []

    commercial_fixtures.each do |item|
      file_content = read_xml("CEPC-8.0.0", item)
      file_array << { xml: Nokogiri.XML(file_content), schema: item.upcase }
    end
    file_array
  end

  def self.get_latest_assessment_id
    sql = <<-SQL
      SELECT MAX(assessment_id) as id FROM assessments
    SQL

    result = ActiveRecord::Base.connection.exec_query(sql, "SQL")

    result.first["id"].to_s.empty? ? "0000-0000-0000-0000-0000" : result.first["id"].to_s
  end

  def self.update_xml(xml_doc, type_of_assessment, id, assessor, date_of_expiry, old_date_of_expiry, date_of_registration, old_date_of_registration, new_address, old_address, linked_id, _old_assessment_id)
    xml = xml_doc.to_s
    xml.sub!("0000-0000-0000-0000-0000", id)
    xml.sub!("0000-0000-0000-0000-0001", linked_id)
    xml.sub!("SPEC000000", assessor["scheme_assessor_id"])
    xml.sub!("111222333", assessor["telephone_number"])
    xml.sub!("a@b.c", assessor["email"])
    xml.sub!(old_address[:address_id], new_address[:address_id])
    xml.sub!(old_address[:address_line1], new_address[:address_line1])

    if %w[rdsap sap dec].include?(type_of_assessment)
      xml.gsub!(old_date_of_registration, date_of_registration)
    else
      xml.gsub!(old_date_of_expiry, date_of_expiry)
    end
    Nokogiri.XML(xml)
  end

  def self.extract_data_from_lodgement_xml(lodgement)
    lodgement.fetch_data
  end

  def self.lodgement_validity
    %w[superseded valid expired]
  end

  def self.lodge_assessments(file_array)
    use_case = ApiFactory.lodge_assessment_use_case
    assessment_id = get_latest_assessment_id
    file_array.each_with_index do |hash, _index|
      assessor = ActiveRecord::Base.connection.exec_query("SELECT scheme_assessor_id, telephone_number, email FROM assessors ORDER BY random() LIMIT 1")[0]

      schema_type = if commercial_fixtures.include? hash[:schema].to_s.downcase
                      "CEPC-8.0.0"
                    else
                      hash[:schema]
                    end

      first_id_in_file_group = assessment_id.dup.next

      lodgement_validity.each do |validity|
        lodgement_data =
          extract_data_from_lodgement_xml Domain::Lodgement.new(hash[:xml].to_xml, schema_type)

        dual_lodgement = lodgement_data.size > 1

        lodgement_data.each_with_index do |assessment_data, index|
          address = assessment_data[:address]
          old_address = address.dup

          previous_assessment_id = assessment_id.dup
          assessment_id = assessment_id.next

          if dual_lodgement && index == 1
            linked_assessment_id = previous_assessment_id
          elsif dual_lodgement && index.zero?
            linked_assessment_id = assessment_id.dup
            linked_assessment_id.next!
          else
            linked_assessment_id = ""
          end

          old_assessment_id = assessment_data[:assessment_id].dup
          old_date_of_registration = assessment_data[:date_of_registration].dup
          old_date_of_expiry = assessment_data[:date_of_expiry].dup

          case validity
          when "superseded"
            date_of_registration = Time.now.utc - 5.years
            date_of_assessment = Time.now - 5.years
            date_of_expiry = Time.now + 5.years
            address[:address_id] = "RRN-#{first_id_in_file_group}"
          when "valid"
            date_of_registration = Time.now.utc - 3600 * 24
            date_of_assessment = Time.now
            date_of_expiry = Time.now + 10.years
            address[:address_id] = "RRN-#{first_id_in_file_group}"
          else
            date_of_registration = Time.now.utc - 15.years
            date_of_assessment = Time.now - 15.years
            date_of_expiry = Time.now - 5.years
            address[:address_id] = address[:address_id].sub!("0", "1")
            address[:address_line1] = "1#{address[:address_line1]}"
          end

          xml_doc = update_xml(hash[:xml], assessment_data[:type_of_assessment].downcase, assessment_id, assessor, date_of_expiry.strftime("%F"), old_date_of_expiry, date_of_registration.strftime("%F"), old_date_of_registration, address, old_address, linked_assessment_id, old_assessment_id)

          data = { assessment_id:,
                   assessor_id: assessor["scheme_assessor_id"],
                   raw_data: xml_doc.to_s,
                   date_of_registration:,
                   type_of_assessment: assessment_data[:type_of_assessment],
                   date_of_assessment:,
                   date_of_expiry:,
                   current_energy_efficiency_rating: assessment_data[:current_energy_efficiency_rating],
                   potential_energy_efficiency_rating: assessment_data[:potential_energy_efficiency_rating],
                   address: }

          begin
            use_case.execute(data, false, schema_type)
            pp "Lodged assessment ID:#{assessment_id}, Type: '#{assessment_data[:type_of_assessment]}', Schema: '#{schema_type}, Validity: '#{validity}'"
          rescue UseCase::LodgeAssessment::DuplicateAssessmentIdException
            pp "skipped lodged assessment ID:#{assessment_id}"
          end
        end
      end
    end
  end
end
