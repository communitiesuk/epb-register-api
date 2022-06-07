describe Helper::JsonHelper do
  let(:helper) { described_class.new }

  context "when converting json to ruby hashes" do
    it "changes top level keys to symbols" do
      result = helper.convert_to_ruby_hash({ "foo" => "Bar" }.to_json)
      expect(result.keys).to include(:foo)
    end

    it "changes nested keys to symbols" do
      result =
        helper.convert_to_ruby_hash({ "foo" => { "bar" => "baz" } }.to_json)
      expect(result[:foo].keys).to include(:bar)
    end

    it "changes top level keys to snake case" do
      result = helper.convert_to_ruby_hash({ "fooBar" => "baz" }.to_json)
      expect(result.keys).to include(:foo_bar)
    end

    it "changes nested level keys to snake case" do
      result = helper.convert_to_ruby_hash({ "fooBar" => { "barBaz" => "boo" } }.to_json)
      expect(result.keys).to include(:foo_bar)
      expect(result[:foo_bar].keys).to include(:bar_baz)
    end

    it "throws an error when validation doesnt match type" do
      schema = { type: "object", required: "firstName" }
      expect { helper.convert_to_ruby_hash("4", schema:) }.to raise_error Boundary::Json::ValidationError
    end

    it "throws an error exposing failed properties when a property constraint fails" do
      schema = { type: "object", required: %w[enum], properties: { enum: { type: "string", enum: %w[THIS THAT] } } }
      expect { helper.convert_to_ruby_hash('{"enum":"ANOTHER"}', schema:) }.to raise_error do |error|
        expect(error.failed_properties).to eq %w[enum]
      end
    end
  end

  context "when converting ruby hashes to json" do
    it "changes top level keys to strings" do
      result = helper.convert_to_json({ foo: "bar" })
      expect(JSON.parse(result).keys).to include("foo")
    end

    it "changes nested keys to strings" do
      result = helper.convert_to_json({ foo: { bar: "baz" } })
      expect(JSON.parse(result)["foo"].keys).to include("bar")
    end

    it "changes top level keys to camel case" do
      result = helper.convert_to_json({ foo_bar: "baz" })
      expect(JSON.parse(result).keys).to include("fooBar")
    end

    it "changes nested level keys to camel case" do
      result = helper.convert_to_json({ foo_bar: { bar_baz: "boo" } })
      expect(JSON.parse(result).keys).to include("fooBar")
      expect(JSON.parse(result)["fooBar"].keys).to include("barBaz")
    end
  end

  context "when extracting failed properties from a validation" do
    context "when there is a known property error in the schema" do
      let(:schema) do
        {
          oneOf: [
            {
              type: "object",
              required: %w[postcode other],
              properties: {
                postcode: {
                  type: "string",
                  pattern: "^[a-zA-Z0-9 ]{4,10}$".freeze,
                },
                other: {
                  type: "string",
                  minLength: 1,
                },
              },
            },
            {
              type: "object",
              required: %w[xyzzy],
              properties: {
                uprn: {
                  type: "string",
                },
              },
            },
          ],
        }.freeze
      end

      let(:json_just_postcode) { '{"postcode":"A0","other":"42"}' }
      let(:json_both_fail) { '{"postcode":"A0","other":""}' }

      it "extracts the failed property when just the postcode fails" do
        expect(helper.extract_failed_properties(schema:, json: json_just_postcode)).to eq %w[postcode]
      end

      it "extracts both properties when two fail" do
        expect(helper.extract_failed_properties(schema:, json: json_both_fail).sort).to eq %w[other postcode]
      end
    end
  end
end
