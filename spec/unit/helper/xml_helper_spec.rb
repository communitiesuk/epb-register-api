# frozen_string_literal: true

describe Helper::XmlHelper do
  let(:helper) { described_class.new }
  let(:xml) { File.read File.join File.dirname(__FILE__), 'xml/example.xml' }
  let(:schema) { File.read File.join File.dirname(__FILE__), 'xml/example.xsd' }
  let(:invalid_xml) do
    File.read File.join File.dirname(__FILE__), 'xml/invalid.xml'
  end

  context 'when validating valid xml' do
    it 'load a valid xml file' do
      response = helper.convert_to_hash(xml, schema)

      expect(response).to be_a Hash
    end

    it 'returns the correct ruby hash' do
      response = helper.convert_to_hash(xml, schema)

      expected_response = {
        shiporder: {
          "orderperson": 'John Smith',
          "shipto": {
            "name": 'Ola Nordmann',
            "address": 'Langgt 23',
            "city": '4000 Stavanger',
            "country": 'Norway'
          },
          "item": [
            {
              "title": 'Empire Burlesque',
              "note": 'Special Edition',
              "quantity": '1',
              "price": '10.90'
            },
            { "title": 'Hide your heart', "quantity": '1', "price": '9.90' }
          ],
          "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance',
          "orderid": '889923',
          "xsi:noNamespaceSchemaLocation": 'example.xsd'
        }
      }

      expect(response).to eq expected_response
    end
  end

  context 'when validating invalid xml' do
    it 'raises an error' do
      expect {
        helper.convert_to_hash(invalid_xml, schema)
      }.to raise_error instance_of Helper::InvalidXml
    end
  end
end
