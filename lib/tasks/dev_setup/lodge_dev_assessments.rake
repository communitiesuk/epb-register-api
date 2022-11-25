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
    %w[ac-cert ac-report cepc cepc-rr dec dec-rr]
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
        file_content = read_xml(schema, "cepc")
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

  def self.update_xml(xml_doc, type_of_assessment, id, assessor, date_of_expiry, date_of_registration, new_address, old_address)
    xml = xml_doc.to_s
    xml.sub!("0000-0000-0000-0000-0000", id)
    xml.sub!("SPEC000000", assessor["scheme_assessor_id"])
    xml.sub!("111222333", assessor["telephone_number"])
    xml.sub!("a@b.c", assessor["email"])
    xml.sub!(old_address[:address_id], new_address[:address_id])
    xml.sub!(old_address[:address_line1], new_address[:address_line1])

    if %w[rdsap sap dec].include?(type_of_assessment)
      xml.gsub!("2020-05-04", date_of_registration)
    else
      xml.gsub!("2024-05-04", date_of_expiry)
    end

    Nokogiri.XML(xml)
  end

  def self.extract_data_from_lodgement_xml(lodgement)
    lodgement.fetch_data
  end

  def self.lodgement_validity
    %w[valid superseded expired]
  end

  def self.lodge_assessments(file_array)
    use_case = ApiFactory.lodge_assessment_use_case
    assessment_id = get_latest_assessment_id
    file_array.each_with_index do |hash, _index|
      assessor = ActiveRecord::Base.connection.exec_query("SELECT scheme_assessor_id, telephone_number, email FROM assessors ORDER BY random() LIMIT 1")[0]

      if commercial_fixtures.include? hash[:schema].to_s.downcase
        schema_type = "CEPC-8.0.0"
        type_of_assessment = hash[:schema]
      else
        schema_type = hash[:schema]
        type_of_assessment = schema_type.split("-").first
      end

      lodgement_data =
        extract_data_from_lodgement_xml Domain::Lodgement.new(hash[:xml].to_xml, schema_type)

      address = lodgement_data[0][:address]
      old_address = address.dup
      current_energy_efficiency_rating = lodgement_data[0][:current_energy_efficiency_rating]
      potential_energy_efficiency_rating = lodgement_data[0][:potential_energy_efficiency_rating]

      lodgement_validity.each do |validity|
        assessment_id = assessment_id.next
        case validity
        when "valid"
          date_of_registration = Time.now.utc - 3600 * 24
          date_of_assessment = Time.now
          date_of_expiry = Time.now + 10.years
        when "superseded"
          date_of_registration = Time.now.utc - 5.years
          date_of_assessment = Time.now - 5.years
          date_of_expiry = Time.now + 5.years
        else
          date_of_registration = Time.now.utc - 15.years
          date_of_assessment = Time.now - 15.years
          date_of_expiry = Time.now - 5.years
          address[:address_id] = address[:address_id].sub!("0", "1")
          address[:address_line1] = "1#{address[:address_line1]}"
        end

        xml_doc = update_xml(hash[:xml], type_of_assessment.downcase, assessment_id, assessor, date_of_expiry.strftime("%F"), date_of_registration.strftime("%F"), address, old_address)

        data = { assessment_id:,
                 assessor_id: assessor["scheme_assessor_id"],
                 raw_data: xml_doc.to_s,
                 date_of_registration:,
                 type_of_assessment:,
                 date_of_assessment:,
                 date_of_expiry:,
                 current_energy_efficiency_rating:,
                 potential_energy_efficiency_rating:,
                 address: }

        begin
          use_case.execute(data, false, schema_type)
          pp "Lodged assessment ID:#{assessment_id}, Type: '#{type_of_assessment}', Schema: '#{schema_type}'"
        rescue UseCase::LodgeAssessment::DuplicateAssessmentIdException
          pp "skipped lodged assessment ID:#{assessment_id}"
        end
      end
    end
  end
end
