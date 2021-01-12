def test_xml_doc(supported_schema, asserted_keys, test_report = false)
  supported_schema.each do |schema|
    view_model =
      ViewModel::Factory.new.create(schema[:xml], schema[:schema_name], nil)

    # test either to has or to report
    view_model.class
    view_model = test_report ? view_model.to_report : view_model.to_hash

    asserted_keys.each do |key, value|
      result = view_model[key]

      if schema.key?(:different_buried_fields) &&
          schema[:different_buried_fields].key?(key)
        value = value.merge(schema[:different_buried_fields][key])
      end

      if schema[:unsupported_fields].include? key
        expect(result).to be_nil,
                          "Failed on #{schema[:schema_name]}:#{key}\n" \
                            "Unsupported fields must return nil, got \"#{result}\""
      elsif schema[:different_fields].key? key
        expect(result).to eq(schema[:different_fields][key]),
                          "Failed on #{schema[:schema_name]}:#{key}\n with different value" \
                            "EXPECTED: \"#{schema[:different_fields][key]}\"\n" \
                            "     GOT: \"#{result}\"\n"
      else
        expect(result).to eq(value),
                          "Failed on #{schema[:schema_name]}:#{schema[:schema_type]}:#{key}\n" \
                            "EXPECTED: \"#{value}\"\n" \
                            "     GOT: \"#{result}\"\n"
      end
    end
  end
end

def lprn_test_value
  "LPRN-000000000001"
end

def uprn_test_value
  lprn_test_value.gsub("LPRN", "UPRN")
end
