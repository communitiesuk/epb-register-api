def test_xml_doc(supported_schema, asserted_keys, method_called = :to_hash)
  supported_schema.each do |schema|
    sample = Samples.xml(schema[:schema], schema[:type] || "epc")

    view_model = ViewModel::Factory.new.create sample,
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
        expect(result).to be_nil, <<~ERROR
          Failed on #{schema[:schema]}:#{schema[:type]}:#{key}
          Unsupported fields must return nil, got "#{result}" (#{result.class})
        ERROR

      elsif schema[:different_fields]&.key? key
        expect(result).to eq(schema[:different_fields][key]), <<~ERROR
          Failed on #{schema[:schema]}:#{schema[:type]}:#{key}
            EXPECTED: "#{schema[:different_fields][key]}" (#{schema[:different_fields][key].class})
                 GOT: "#{result}" (#{result.class})
        ERROR
      else
        expect(result).to eq(value), <<~ERROR
          Failed on #{schema[:schema]}:#{schema[:type]}:#{key}
            EXPECTED: "#{value}" (#{value.class})
                 GOT: "#{result}" (#{result.class})
        ERROR
      end
    end
  end
end
