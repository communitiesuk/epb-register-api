# frozen_string_literal: true

describe Helper::XmlHelper do
  let(:helper) { described_class }
  let(:xml) { File.read File.join File.dirname(__FILE__), "xml/example.xml" }
  let(:schema) { File.join File.dirname(__FILE__), "xml/example.xsd" }

  describe ".convert_to_hash" do
    it "loads a valid XML file" do
      response = helper.convert_to_hash(xml, schema:)

      expect(response).to be_a Hash
    end

    it "returns the correct ruby hash" do
      response = helper.convert_to_hash(xml, schema:)

      expected_response = {
        shiporder: {
          "orderperson": "John Smith",
          "shipto": {
            "name": "Ola Nordmann",
            "address": "Langgt 23",
            "city": "4000 Stavanger",
            "country": "Norway",
          },
          "item": [
            {
              "title": "Empire Burlesque",
              "note": "Special Edition",
              "quantity": "1",
              "price": "10.90",
            },
            { "title": "Hide your heart", "quantity": "1", "price": "9.90" },
          ],
          "test_data": nil,
          "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
          "orderid": "889923",
          "xsi:noNamespaceSchemaLocation": "example.xsd",
        },
      }

      expect(response).to eq expected_response
    end

    it "raises an error for invalid xml" do
      expect {
        helper.convert_to_hash(<<~XML, schema:)
          <xml>
            <foo>
          </xml>
        XML
      }.to raise_error Helper::InvalidXml, "3:7: FATAL: Opening and ending tag mismatch: foo line 2 and xml"
    end

    it "raises an error for valid xml that does not match the schema" do
      expect {
        helper.convert_to_hash(<<~XML, schema:)
          <?xml version="1.0" encoding="utf-8"?>
          <foo>
            <bar />
          </foo>
        XML
      }.to raise_error Helper::InvalidXml, "2:0: ERROR: Element 'foo': No matching global declaration available for the validation root."
    end
  end
end
