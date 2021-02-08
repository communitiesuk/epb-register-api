def test_xml_doc(schemas, assertion, method_called = :to_hash)
  schemas.each do |schema_case|
    schema_case[:type] = "epc" unless schema_case[:type]

    sample = Samples.xml(schema_case[:schema], schema_case[:type])

    schema_path = Helper::SchemaListHelper.new(schema_case[:schema]).schema_path
    schema =
      Nokogiri::XML::Schema.from_document Nokogiri.XML(
        File.read(schema_path),
        schema_path,
      )
    validation = schema.validate(Nokogiri.XML(sample))

    expect(validation).to be_empty, <<~ERROR
      Failed on #{schema_case[:schema]}:#{schema_case[:type]}
        This document does not validate against the chosen schema,
          Errors:
            #{validation.join('\n')}
    ERROR

    view_model = ViewModel::Factory.new.create sample, schema_case[:schema], nil

    source_hash = view_model.method(method_called).call

    assertion.each do |key, value|
      result = source_hash[key]

      if schema_case.key?(:different_buried_fields) &&
          schema_case[:different_buried_fields].key?(key)
        value = value.merge(schema_case[:different_buried_fields][key])
      end

      if schema_case[:unsupported_fields]&.include? key
        expect(result).to be_nil, <<~ERROR
          Failed on #{schema_case[:schema]}:#{schema_case[:type]}:#{key}
            Unsupported fields must return nil, got "#{result}" (#{result.class})
        ERROR
      elsif schema_case[:different_fields]&.key? key
        expect(result).to eq(schema_case[:different_fields][key]), <<~ERROR
          Failed on #{schema_case[:schema]}:#{schema_case[:type]}:#{key}
            EXPECTED: "#{schema_case[:different_fields][key]}" (#{schema_case[:different_fields][key].class})
                 GOT: "#{result}" (#{result.class})
        ERROR
      else
        expect(result).to eq(value), <<~ERROR
          Failed on #{schema_case[:schema]}:#{schema_case[:type]}:#{key}
            EXPECTED: "#{value}" (#{value.class})
                 GOT: "#{result}" (#{result.class})
        ERROR
      end
    end
  end
end
