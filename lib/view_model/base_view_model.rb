module ViewModel
  class BaseViewModel
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

    def building_reference_number
      assessments_address_id_gateway = Gateway::AssessmentsAddressIdGateway.new
      assessments_address_id_gateway.fetch(assessment_id)[:address_id]
    end
  end
end
