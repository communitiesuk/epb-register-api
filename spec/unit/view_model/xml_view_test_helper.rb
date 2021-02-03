def test_xml_doc(supported_schema, asserted_keys, method_called = :to_hash)
  supported_schema.each do |schema|
    view_model =
      ViewModel::Factory.new.create Samples.xml(schema[:schema], schema[:type] || "epc"),
                                    schema[:schema],
                                    nil

    source_hash = view_model.method(method_called).call

    asserted_keys.each do |key, value|
      result = source_hash[key]

      if schema.key?(:different_buried_fields) &&
          schema[:different_buried_fields].key?(key)
        value = value.merge(schema[:different_buried_fields][key])
      end

      if schema[:unsupported_fields]&.include? key
        expect(result).to be_nil,
                          "Failed on #{schema[:schema]}:#{schema[:type]}:#{key}\n" \
                            "Unsupported fields must return nil, got \"#{result}\""
      elsif schema[:different_fields]&.key? key
        expect(result).to eq(schema[:different_fields][key]),
                          "Failed on #{schema[:schema]}:#{schema[:type]}:#{key}\n with different value" \
                            "EXPECTED: \"#{schema[:different_fields][key]}\" (#{schema[:different_fields][key].class})\n" \
                            "     GOT: \"#{result}\" (#{result.class})\n"
      else
        expect(result).to eq(value),
                          "Failed on #{schema[:schema]}:#{schema[:type]}:#{schema[:schema_type]}:#{key}\n" \
                            "EXPECTED: \"#{value}\" (#{value.class})\n" \
                            "     GOT: \"#{result}\" (#{result.class})\n"
      end
    end
  end
end
