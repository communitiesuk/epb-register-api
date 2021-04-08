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
      existing_assessment_address_id =
        AssessmentsAddressId.find_by assessment_id: record[:assessment_id]
      AssessmentsAddressId.create(record) if existing_assessment_address_id.nil?
    end

    def update_assessments_address_id_mapping(
      assessment_ids,
      new_address_id,
      new_source = "epb_team_update"
    )
      ActiveRecord::Base.transaction do
        assessment_ids.each do |assessment_id|
          update_address_id(assessment_id, new_address_id, new_source)
        end
      end
    end

  private

    def update_address_id(
      assessment_id,
      new_address_id,
      new_source = "epb_team_update"
    )
      assessment_address_id_row =
        AssessmentsAddressId.find_by assessment_id: assessment_id
      assessment_address_id_row.update(
        { "address_id" => new_address_id, "source" => new_source },
      )
    end
  end
end
