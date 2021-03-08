def test_date
  "2021-02-22"
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
