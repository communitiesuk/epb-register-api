# frozen_string_literal: true
shared_context "common" do
  before do
    @enum_built_form =
      {
        "1" => "Detached",
        "2" => "Semi-Detached",
        "3" => "End-Terrace",
        "4" => "Mid-Terrace",
        "5" => "Enclosed End-Terrace",
        "6" => "Enclosed Mid-Terrace",
        "NR" => "Not Recorded",
      }
  end
end

describe Helper::XmlEnumsToOutput do
  let(:helper) { described_class }
  include_context("common")

  context "when the XML does not have the specified node" do
    it "returns nil for Open Data Communities" do
      response = helper.xml_value_to_string(nil)
      expect(response).to be_nil
    end
  end

  context "when the XML does have the specified node" do
    it "returns the string when you pass as the argument" do
      @enum_built_form.each do |key, value|
        response = helper.xml_value_to_string(key)
        expect(response).to eq(value)
      end
    end
  end

  context "when the XML contains any other value outside of the enum" do
    it "returns nil for Open Data Communities" do
      response = helper.xml_value_to_string("Any other value")
      expect(response).to be_nil
    end
  end
end
