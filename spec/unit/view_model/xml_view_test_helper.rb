def test_xml_doc(supported_schema, asserted_keys)
  supported_schema.each do |schema|
    xml_file = File.read File.join Dir.pwd, schema[:xml_file]

    view_model =
      ViewModel::Factory.new.create(xml_file, schema[:schema_name], nil)
        .to_hash

    asserted_keys.each do |key, value|
      result = view_model[key]
      if schema[:unsupported_fields].include? key
        expect(result).to be_nil,
                          "Failed on #{schema[:schema_name]}:#{key}\n" \
                            "Unsupported fields must return nil, got \"#{result}\""
      elsif !schema[:different_fields][key].nil?
        expect(result).to eq(schema[:different_fields][key]),
                          "Failed on #{schema[:schema_name]}:#{key}\n" \
                            "EXPECTED: \"#{schema[:different_fields][key]}\"\n" \
                            "     GOT: \"#{result}\"\n"
      else
        expect(result).to eq(value),
                          "Failed on #{schema[:schema_name]}:#{key}\n" \
                            "EXPECTED: \"#{value}\"\n" \
                            "     GOT: \"#{result}\"\n"
      end
    end
  end
end
