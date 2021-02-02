module ViewModel
  class Base
    def initialize(xml)
      @xml_doc = Nokogiri.XML xml
    end

    def xpath(queries, node = @xml_doc)
      queries.each do |query|
        if node
          node = node.at query
        else
          return nil
        end
      end
      node ? node.content : nil
    end
  end
end
