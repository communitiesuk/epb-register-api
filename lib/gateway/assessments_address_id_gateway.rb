# frozen_string_literal: true

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.uncountable "assessments_address_id"
end

module Gateway
  class AssessmentsAddressIdGateway
    class AssessmentsAddressId < ActiveRecord::Base
    end

    def fetch(assessment_id)
      AssessmentsAddressId.find(assessment_id).as_json.symbolize_keys
    end

    def send_to_db(record)
      if record[:address_id].nil?
        record[:address_id] = "RRN-" + record[:assessment_id]
      elsif record[:address_id].start_with?("UPRN-")
        sql = "SELECT uprn FROM address_base WHERE uprn = $1"

        binds = [
          ActiveRecord::Relation::QueryAttribute.new(
            "uprn",
            record[:address_id][5..-1].to_i.to_s,
            ActiveRecord::Type::String.new,
          ),
        ]

        result = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)

        record[:address_id] = "RRN-" + record[:assessment_id] if result.empty?
      end

      existing_assessment_address_id =
        AssessmentsAddressId.find_by assessment_id: record[:assessment_id]

      AssessmentsAddressId.create(record) if existing_assessment_address_id.nil?
    end

    def update_assessment_address_id_mapping(assessment_id, new_address_id, new_source = "epb_team_update")
      assessment_address_id_row =
        AssessmentsAddressId.find_by assessment_id: assessment_id
      assessment_address_id_row.update({ "address_id" => new_address_id, "source" => new_source})
    end
  end
end
