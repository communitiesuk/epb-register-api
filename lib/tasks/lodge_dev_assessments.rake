
desc "Lodge assessments to the dev databse for testing"


SCHEME_ARRAY  =  %w[CEPC-8.0.0 CEPC-NI-8.0.0 RdSAP-Schema-20.0.0 RdSAP-Schema-NI-20.0.0  SAP-Schema-18.0.0 SAP-Schema-NI-18.0.0]
ASSESSOR_ID = 'RAKE000001'
SCHEME_NAME = 'rake-scheme01'

task :lodge_dev_assessments do
  if ! DevAssessmentsHelper.production?
    scheme_id = DevAssessmentsHelper.add_rake_scheme
    DevAssessmentsHelper.add_assessor(scheme_id)
    DevAssessmentsHelper.clean_tables(ASSESSOR_ID)
    DevAssessmentsHelper.lodge_assessments(DevAssessmentsHelper.read_fixtures(SCHEME_ARRAY))
  else
    pp 'aborted as in production'
  end
end

class DevAssessmentsHelper

  def self.production?
    ActiveRecord::Base.connection.exec_query("SELECT COUNT(*) as cnt FROM assessments ", "SQL")
    result.first["cnt"].to_i  > 1000000 ? true :false
  end

def self.clean_tables(assessor_id)
  sql = <<-SQL
    DELETE FROM assessments_xml x
        USING assessments a WHERE a.assessment_id = x.assessment_id AND scheme_assessor_id =  '#{assessor_id}'
  SQL

  ActiveRecord::Base.connection.exec_query(sql, "SQL")
  ActiveRecord::Base.connection.exec_query("DELETE FROM assessments WHERE scheme_assessor_id =  '#{ASSESSOR_ID}'", "SQL")

end

def self.lodge_assessments(file_array)
  use_case = UseCase::LodgeAssessment.new
  id = get_latest_assessment_id

  file_array.each_with_index { |xml, index |
      sanitised_xml = Helper::SanitizeXmlHelper.new.sanitize(xml.to_s)
      id = id.next
      assessment_type = SCHEME_ARRAY[index]
      data = {assessment_id: id,
              assessor_id: ASSESSOR_ID,
              raw_data:sanitised_xml,
              date_of_registration: DateTime.yesterday,
              type_of_assessment: assessment_type,
              date_of_assessment: Time.now,
              date_of_expiry: Time.now + 10.years,
              current_energy_efficiency_rating: 1,
              potential_energy_efficiency_rating: 1,
              address: {address_id:'UPRN-000000000001',
                        address_line1: "Some Unit", address_line2:"2 Lonely Street", address_line3: "Some Area",
                        address_line4: "",
                        town:"London", postcode:"SW1A 2AA"

              },
        }

      begin
      use_case.execute(data, false, SCHEME_ARRAY[index] )
      pp "Lodged assessment ID:#{id}, Type: '#{assessment_type}'"

      rescue UseCase::LodgeAssessment::DuplicateAssessmentIdException
        pp "skipped lodged assessment ID:#{id}"
      end
  }

end




def self.read_fixtures(scheme_array)
  file_array = []
  scheme_array.each do | scheme |
    file_content = read_xml(scheme, scheme.include?('CEPC') ? 'cepc' : 'epc')
    file_array << Nokogiri.XML(file_content)
  end
  file_array
end


def self.read_xml(schema, type = "epc")
  path = File.join Dir.pwd, "spec/fixtures/samples/#{schema}/#{type}.xml"

  unless File.exist? path
    raise ArgumentError,
          "No #{type} sample found for schema #{schema}, create one at #{
            path
          }"
  end

  File.read path
end


def self.add_rake_scheme
  insert_sql = <<-SQL
            INSERT INTO schemes(name,active)
            VALUES ('#{SCHEME_NAME}', true)
  SQL
  begin
    ActiveRecord::Base.connection.insert(insert_sql, "SQL")
  rescue ActiveRecord::RecordNotUnique
    ActiveRecord::Base.connection.exec_query("SELECT scheme_id FROM schemes WHERE name ='#{SCHEME_NAME}'", "SQL").first["scheme_id"]
  end

end

def self.add_assessor(scheme_id)
  insert_sql = <<-SQL
            INSERT INTO assessors(scheme_assessor_id, first_name,last_name,date_of_birth,registered_by,telephone_number,email,domestic_rd_sap_qualification,non_domestic_sp3_qualification,non_domestic_cc4_qualification,
non_domestic_dec_qualification,non_domestic_nos3_qualification,non_domestic_nos5_qualification,non_domestic_nos4_qualification,domestic_sap_qualification,gda_qualification)
            VALUES ('#{ASSESSOR_ID}', 'test_forename', 'test_surname', '1970-01-05', #{scheme_id}, '0202207459', 'test@barr.com', 'ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE', 'ACTIVE','ACTIVE','ACTIVE','ACTIVE','ACTIVE')
  SQL
  begin
    ActiveRecord::Base.connection.insert(insert_sql, "SQL")
  rescue ActiveRecord::RecordNotUnique
  end

end

def self.get_latest_assessment_id
  sql = <<-SQL
    SELECT MAX(assessment_id) as id FROM assessments
  SQL

  result = ActiveRecord::Base.connection.exec_query(sql, "SQL")

  result.first["id"].to_s.empty? ? '0000-0000-0000-0000-0000' : result.first["id"].to_s

end
end
