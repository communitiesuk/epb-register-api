def test_start_date
  "2021-02-22"
end

def test_to_date
  "2021-03-01"
end

def redact_lodgement_datetime(csv_object)
  array = csv_object.to_a
  array.reject { |k| k[0] == "LODGEMENT_DATETIME" }
end

def file_name(assessment_type)
  "open_data_export_#{assessment_type.downcase}_#{DateTime.now.strftime('%F')}_1.csv"
end

def regex_body(array)
  str = ""
  array.each { |item| str << "(?=^.*?#{item}.*$)" }
  Regexp.new("#{str}.*$")
end

def read_csv_fixture(file_name, parse = true)
  fixture_path = File.dirname __FILE__.gsub("acceptance/reporting", "")
  fixture_path << "/fixtures/open_data_export/csv/"
  read_file = File.read("#{fixture_path}#{file_name}.csv")
  CSV.parse(read_file, headers: true) if parse
end

def lodge_assessor
  scheme_id = add_scheme_and_get_id
  add_assessor(
    scheme_id: scheme_id,
    assessor_id: "SPEC000000",
    body: AssessorStub.new.fetch_request_body(
      non_domestic_nos3: "ACTIVE",
      non_domestic_nos4: "ACTIVE",
      non_domestic_nos5: "ACTIVE",
      non_domestic_dec: "ACTIVE",
      domestic_rd_sap: "ACTIVE",
      domestic_sap: "ACTIVE",
      non_domestic_sp3: "ACTIVE",
      non_domestic_cc4: "ACTIVE",
      gda: "ACTIVE",
    ),
  )
  scheme_id
end

def get_assessment_xml(schema, id, date_registered, type = "")
  xml =
    if type.empty?
      Nokogiri.XML(Samples.xml(schema))
    else
      Nokogiri.XML(Samples.xml(schema, type))
    end
  assessment_id_node =
    type == "cepc" ? xml.at("//*[local-name() = 'RRN']") : xml.at("RRN")
  assessment_id_node.children = id
  xml.at("//*[local-name() = 'Registration-Date']").children = date_registered
  xml
end

def get_recommendations_xml(schema, date_registered, type, assesment_id_part)
  index_value = type.include?("cepc") ? 2 : 4
  rr_xml = Nokogiri.XML Samples.xml(schema, type)
  rr_xml
    .xpath("//*[local-name() = 'RRN']")
    .each_with_index do |node, index|
      node.content =
        "#{assesment_id_part}-0000-0000-0000-000#{index + index_value}"
    end

  rr_xml
    .xpath("//*[local-name() = 'Related-RRN']")
    .reverse
    .each_with_index do |node, index|
      node.content =
        "#{assesment_id_part}-0000-0000-0000-000#{index + index_value}"
    end

  rr_xml
    .xpath("//*[local-name() = 'Registration-Date']")
    .reverse_each { |node| node.content = date_registered }

  rr_xml
end

def validate_date_range(date_from, date_to)
  date_from <= date_to
end
