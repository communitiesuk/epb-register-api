# frozen_string_literal: true

require 'nokogiri'

test = 'api/schemas/xml/RdSAP-Schema-19.0/RdSAP/Templates/RdSAP-Report.xsd'
doc = 'api/schemas/xml/examples/RdSAP-19.01.xml'

xsddoc = Nokogiri.XML(File.read(test), test)
xsd = Nokogiri::XML::Schema.from_document(xsddoc)
doc = Nokogiri.XML(File.read(doc))

xsd.validate(doc).each { |error| puts error.message }

#xml = <<-EOS
#<parentNode>
#  <amount id="asdfasdfadsf">12.0</amount>
#  <authIdCode>999999</authIdCode>
#  <currency>USD</currency>
#  <p><a>asdfasdfasdf</a></p>
#</ parentNode>
#EOS
#document = Nokogiri.XML(xml)
#
#hash =
#  document.xpath('/*/*').each_with_object({}) do |node, hash|
#    hash[node.name] = node.text
#  end
#
#pp Hash[document.search('*/*').map { |n| [n.name, n.text] }]

#p hash # => {"amount"=>"12.0", "authIdCode"=>"999999", "currency"=>"USD"}

#let(:xml) { File.read 'api/schemas/xml/examples/RdSAP-19.01.xml' }
