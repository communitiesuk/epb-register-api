# frozen_string_literal: true

require "date"

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.uncountable "assessments_address_id"
end

module Gateway
  class AssessmentsAddressIdGateway
    class AssessmentsAddressId < ActiveRecord::Base
    end

    class AssessmentsAddressIdScotland < ActiveRecord::Base
      self.table_name = "scotland.assessments_address_id"
    end

    def fetch(assessment_id, is_scottish: false)
      is_scottish ? AssessmentsAddressIdScotland.find(assessment_id).as_json.symbolize_keys : AssessmentsAddressId.find(assessment_id).as_json.symbolize_keys
    end

    def send_to_db(record, is_scottish: false)
      if is_scottish
        existing_assessment_address_id =
          AssessmentsAddressIdScotland.find_by assessment_id: record[:assessment_id]
        AssessmentsAddressIdScotland.create(record) if existing_assessment_address_id.nil?
      else
        existing_assessment_address_id =
          AssessmentsAddressId.find_by assessment_id: record[:assessment_id]
        AssessmentsAddressId.create(record) if existing_assessment_address_id.nil?
      end
    end

    def update_assessments_address_id_mapping(
      assessment_ids,
      new_address_id,
      new_source = "epb_team_update",
      address_updated_at = Time.now
    )
      ActiveRecord::Base.transaction do
        assessment_ids.each do |assessment_id|
          update_address_id(assessment_id, new_address_id, new_source, address_updated_at)
        end
      end
    end

    def fetch_updated_group_count(day_date)
      sql = <<-SQL
      SELECT COUNT(DISTINCT address_id) as cnt FROM assessments_address_id
      WHERE source = 'epb_bulk_linking'
      AND to_char(address_updated_at, 'YYYY-MM-dd') = $1;
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "day_date",
          day_date,
          ActiveRecord::Type::Date.new,
        ),
      ]

      result = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)
      result.map { |rows| rows["cnt"] }.first
    end

    def fetch_updated_address_id_count(day_date)
      sql = <<-SQL
      SELECT COUNT(*) as cnt FROM assessments_address_id
      WHERE source = 'epb_bulk_linking'
      AND to_char(address_updated_at, 'YYYY-MM-dd') = $1;
      SQL

      binds = [
        ActiveRecord::Relation::QueryAttribute.new(
          "day_date",
          day_date,
          ActiveRecord::Type::Date.new,
        ),
      ]

      result = ActiveRecord::Base.connection.exec_query(sql, "SQL", binds)
      result.map { |rows| rows["cnt"] }.first
    end

    def update_matched_address_id(
      assessment_id,
      new_matched_address_id,
      new_confidence
    )
      assessment_address_id_row =
        AssessmentsAddressId.find_by(assessment_id:)
      assessment_address_id_row.update(
        { "matched_address_id" => new_matched_address_id, "matched_confidence" => new_confidence },
      )
    end

  private

    def update_address_id(
      assessment_id,
      new_address_id,
      new_source = "epb_team_update",
      address_updated_at = Time.now
    )
      assessment_address_id_row =
        AssessmentsAddressId.find_by(assessment_id:)
      assessment_address_id_row.update(
        { "address_id" => new_address_id, "source" => new_source, "address_updated_at" => address_updated_at },
      )
    end
  end
end
