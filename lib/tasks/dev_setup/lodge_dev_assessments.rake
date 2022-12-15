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
      file_array << { xml: Nokogiri.XML(file_content), type: item.upcase, schema: "CEPC-8.0.0" }

      file_content = read_xml("CEPC-NI-8.0.0", item)
      file_array << { xml: Nokogiri.XML(file_content), type: item.upcase, schema: "CEPC-NI-8.0.0" }
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

  def self.update_xml(xml_doc:, schema_type:, type_of_lodgement:, linked_id:, new_lodgement_assessment_id:, assessor:, old_address:, new_address:, old_date_of_assessment:, date_of_assessment:, old_date_of_registration:, date_of_registration:, old_address_id:, new_address_id:, old_date_of_expiry:, date_of_expiry:)
    xml = xml_doc.to_s
    xml.gsub!("0000-0000-0000-0000-0001", linked_id)
    xml.gsub!("0000-0000-0000-0000-0000", new_lodgement_assessment_id)
    xml.gsub!("SPEC000000", assessor["scheme_assessor_id"])
    xml.gsub!("111222333", assessor["telephone_number"])
    xml.gsub!("a@b.c", assessor["email"])
    xml.gsub!(old_address[:address_line1], new_address[:address_line1])
    xml.gsub!(old_date_of_assessment, date_of_assessment)
    xml.gsub!(old_date_of_registration, date_of_registration)

    unless ["SAP-Schema-16.3", "SAP-Schema-13.0", "SAP-Schema-10.2"].include?(schema_type)
      xml.gsub!(old_address_id, new_address_id)
    end

    if %w[ac-cert ac-cert+ac-report cepc cepc+rr dec dec+rr].include?(type_of_lodgement.downcase)
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

  def self.as_parsed_document(xml)
    xml_doc = Nokogiri.XML xml
    xml_doc.remove_namespaces!
    xml_doc
  end

  def self.lodge_assessments(file_array)
    use_case = ApiFactory.validate_and_lodge_assessment_use_case
    file_array.each_with_index do |hash, _index|
      assessor = ActiveRecord::Base.connection.exec_query("SELECT scheme_assessor_id, registered_by, telephone_number, email FROM assessors ORDER BY random() LIMIT 1")[0]
      schema_type = hash[:schema]
      type_of_lodgement = if commercial_fixtures.include? hash[:type].to_s.downcase
                            hash[:type]
                          else
                            schema_type.split("-").first
                          end

      first_id_in_file_group = get_latest_assessment_id.dup.next!

      lodgement_validity.each do |validity|
        lodgement_data =
          extract_data_from_lodgement_xml Domain::Lodgement.new(hash[:xml].to_xml, schema_type)

        fixture_xml = as_parsed_document hash[:xml].to_xml
        dual_lodgement = lodgement_data.size > 1
        address = lodgement_data[0][:address]
        old_address = address.dup
        old_address_id = old_address[:address_id]

        new_lodgement_assessment_id = get_latest_assessment_id.next!

        if dual_lodgement
          linked_assessment_id = new_lodgement_assessment_id.dup
          linked_assessment_id.next!
        else
          linked_assessment_id = ""
        end

        old_date_of_registration = lodgement_data[0][:date_of_registration].dup

        old_date_of_expiry = if ["DEC+RR"].include?(type_of_lodgement)
                               fixture_xml.at("//Valid-Until").text
                             else
                               lodgement_data[0][:date_of_expiry].dup
                             end

        old_date_of_assessment = lodgement_data[0][:date_of_assessment].dup

        time_now = Time.now.utc

        case validity
        when "superseded"
          date_of_registration = time_now - 5.years
          date_of_assessment = time_now - 5.years
          new_address_id = "RRN-#{first_id_in_file_group}"
        when "valid"
          date_of_registration = time_now
          date_of_assessment = time_now
          new_address_id = "RRN-#{first_id_in_file_group}"
        else
          date_of_registration = time_now - 15.years
          date_of_assessment = time_now - 15.years
          new_address_id = address[:address_id].sub!("0", "1")
          address[:address_line1] = "1#{address[:address_line1]}"
        end

        date_of_expiry = if ["DEC+RR"].include?(type_of_lodgement)
                           lodgement_data[0][:date_of_expiry].dup.to_time
                         else
                           date_of_assessment + 10.years - 3600 * 24
                         end

        xml_doc = update_xml(xml_doc: hash[:xml],
                             schema_type:,
                             type_of_lodgement: type_of_lodgement.downcase,
                             linked_id: linked_assessment_id,
                             new_lodgement_assessment_id:,
                             assessor:,
                             old_address:,
                             new_address: address,
                             old_date_of_assessment:,
                             date_of_assessment: date_of_assessment.strftime("%F"),
                             old_date_of_registration:,
                             date_of_registration: date_of_registration.strftime("%F"),
                             old_address_id:,
                             new_address_id:,
                             date_of_expiry: date_of_expiry.strftime("%F"),
                             old_date_of_expiry:)

        begin
          scheme_ids = [assessor["registered_by"]]
          use_case.execute(assessment_xml: xml_doc.to_s, schema_name: schema_type, scheme_ids:, migrated: true, overridden: false)
          pp "Lodged assessment ID:#{new_lodgement_assessment_id}, Type: '#{type_of_lodgement}', Schema: '#{schema_type}, Validity: '#{validity}'"
          if ["SAP-Schema-16.3", "SAP-Schema-13.0", "SAP-Schema-10.2"].include?(schema_type) && %w[valid superseded].include?(validity)
            ActiveRecord::Base.connection.exec_query("UPDATE assessments SET address_id = '#{new_address_id}' WHERE assessment_id = '#{new_lodgement_assessment_id}'")
            ActiveRecord::Base.connection.exec_query("UPDATE assessments_address_id SET address_id = '#{new_address_id}' WHERE assessment_id = '#{new_lodgement_assessment_id}'")
          end
        rescue UseCase::LodgeAssessment::DuplicateAssessmentIdException
          pp "skipped lodged assessment ID:#{new_lodgement_assessment_id}"
        end
      end
    end
  end
end
