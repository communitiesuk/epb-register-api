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
      expect { helper.convert_to_ruby_hash("4", schema: schema) }.to raise_exception(
        JSON::Schema::ValidationError,
      )
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
end
