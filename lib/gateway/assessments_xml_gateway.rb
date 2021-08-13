# frozen_string_literal: true

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.uncountable "assessments_xml"
end

module Gateway
  class AssessmentsXmlGateway
    class AssessmentsXml < ActiveRecord::Base
    end

    def send_to_db(record)
      AssessmentsXml.create(record)
    end

    def fetch(assessment_id)
      result = AssessmentsXml.find_by(assessment_id: assessment_id)
      result ? { xml: result["xml"], schema_type: result["schema_type"] } : nil
    end
  end
end
