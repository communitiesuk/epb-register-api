def read_json_fixture(file_name)
  path = File.join(Dir.pwd, "spec/fixtures/json_export/#{file_name}.json")
  file = File.read(path)
  JSON.parse(file, symbolize_names: true)
end
