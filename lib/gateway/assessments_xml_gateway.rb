# frozen_string_literal: true

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.uncountable "assessments_xml"
end

module Gateway
  class AssessmentsXmlGateway
    def send_to_db(record); end
  end
end
