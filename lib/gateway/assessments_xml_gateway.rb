# frozen_string_literal: true

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.uncountable "assessments_xml"
end

module Gateway
  class AssessmentsXmlGateway
    class AssessmentsXml < ActiveRecord::Base
    end

    class AssessmentsXmlScotland < ActiveRecord::Base
      self.table_name = "scotland.assessments_xml"
    end

    def send_to_db(record, is_scottish)
      is_scottish ? AssessmentsXmlScotland.create(record) : AssessmentsXml.create(record)
    end

    def fetch(assessment_id)
      result = AssessmentsXml.find_by(assessment_id:)
      result ? { xml: result["xml"], schema_type: result["schema_type"] } : nil
    end
  end
end
