# frozen_string_literal: true

module Gateway
  class AssessmentsGateway
    class Assessment < ActiveRecord::Base; end
    class DomesticEpcEnergyImprovement < ActiveRecord::Base; end

    def valid_energy_rating(rating)
      rating.is_a?(Integer) && rating.positive?
    end

    def row_to_energy_improvement(row)
      Domain::RecommendedImprovement.new(
        assessment_id: row[:assessment_id],
        sequence: row[:sequence],
        improvement_code: row[:improvement_code],
        indicative_cost: row[:indicative_cost],
        typical_saving: row[:typical_saving],
        improvement_category: row[:improvement_category],
        improvement_type: row[:improvement_type],
        improvement_title: row[:improvement_title],
        improvement_description: row[:improvement_description],
        energy_performance_rating_improvement:
          row[:energy_performance_rating_improvement],
        environmental_impact_rating_improvement:
          row[:environmental_impact_rating_improvement],
        green_deal_category_code: row[:green_deal_category_code],
      )
    end

    def fetch(assessment_id)
      energy_assessment_record =
        Assessment.find_by(assessment_id: assessment_id)

      improvement_records =
        DomesticEpcEnergyImprovement.where(assessment_id: assessment_id)
      improvements =
        improvement_records.map { |i| row_to_energy_improvement(i).to_hash }

      return unless energy_assessment_record

      rec = energy_assessment_record.attributes.symbolize_keys!
      rec[:recommended_improvements] = improvements

      Domain::Assessment.new(rec)
    end

    def insert_or_update(assessment)
      unless valid_energy_rating(
        assessment.get(:current_energy_efficiency_rating),
      )
        raise ArgumentError, "Invalid current energy rating"
      end

      unless valid_energy_rating(
        assessment.get(:potential_energy_efficiency_rating),
      )
        raise ArgumentError, "Invalid potential energy rating"
      end

      send_to_db(assessment)
    end

    def search_by_postcode(postcode)
      sql =
        "SELECT
            scheme_assessor_id, assessment_id, date_of_assessment, date_registered, dwelling_type,
            type_of_assessment, total_floor_area, current_energy_efficiency_rating,
            potential_energy_efficiency_rating, opt_out, postcode, date_of_expiry,
            address_line1, address_line2, address_line3, address_line4, town,
            current_space_heating_demand, current_water_heating_demand, impact_of_loft_insulation,
            impact_of_cavity_insulation, impact_of_solid_wall_insulation,
            current_carbon_emission, potential_carbon_emission, property_summary, related_party_disclosure_number,
            related_party_disclosure_text, cancelled_at, not_for_issue_at
        FROM assessments
        WHERE postcode = '#{
          ActiveRecord::Base.sanitize_sql(postcode)
        }' AND type_of_assessment IN('RdSAP', 'SAP')
          AND cancelled_at IS NULL
          AND opt_out = false"
      response = Assessment.connection.execute(sql)
      result = []

      response.each do |row|
        row.symbolize_keys!
        row[:property_summary] = JSON.parse(row[:property_summary])
        assessment_domain = Domain::Assessment.new(row)

        result << assessment_domain
      end

      result
    end

    def search_by_assessment_id(assessment_id)
      sql =
        "SELECT
          scheme_assessor_id, assessment_id, date_of_assessment, date_registered, dwelling_type,
          type_of_assessment, total_floor_area, current_energy_efficiency_rating,
          potential_energy_efficiency_rating, opt_out, postcode, date_of_expiry,
          address_line1, address_line2, address_line3, address_line4, town,
          current_space_heating_demand, current_water_heating_demand, impact_of_loft_insulation,
          impact_of_cavity_insulation, impact_of_solid_wall_insulation,
          current_carbon_emission, potential_carbon_emission, property_summary, related_party_disclosure_number,
           related_party_disclosure_text, cancelled_at, not_for_issue_at
          FROM assessments
        WHERE assessment_id = '#{
          ActiveRecord::Base.sanitize_sql(assessment_id)
        }' AND type_of_assessment IN('RdSAP', 'SAP')"

      response = Assessment.connection.execute(sql)

      result = []
      response.each do |row|
        row.symbolize_keys!
        row[:property_summary] = JSON.parse(row[:property_summary])
        assessment_domain = Domain::Assessment.new(row)

        result << assessment_domain
      end

      result
    end

    def search_by_street_name_and_town(street_name, town)
      sql =
        "SELECT
          scheme_assessor_id, assessment_id, date_of_assessment, date_registered, dwelling_type,
          type_of_assessment, total_floor_area, current_energy_efficiency_rating,
          potential_energy_efficiency_rating, opt_out, postcode, date_of_expiry,
          address_line1, address_line2, address_line3, address_line4, town,
          current_space_heating_demand, current_water_heating_demand, impact_of_loft_insulation,
          impact_of_cavity_insulation, impact_of_solid_wall_insulation,
          current_carbon_emission, potential_carbon_emission, property_summary, related_party_disclosure_number,
          related_party_disclosure_text, cancelled_at, not_for_issue_at
        FROM assessments
        WHERE (address_line1 ILIKE '%#{
          ActiveRecord::Base.sanitize_sql(street_name)
        }' OR address_line2 ILIKE '%#{
          ActiveRecord::Base.sanitize_sql(street_name)
        }' OR address_line3 ILIKE '%#{
          ActiveRecord::Base.sanitize_sql(street_name)
        }') AND (town ILIKE '#{
          ActiveRecord::Base.sanitize_sql(town)
        }')
         AND type_of_assessment IN('RdSAP', 'SAP')"

      response = Assessment.connection.execute(sql)

      result = []
      response.each do |row|
        row.symbolize_keys!
        row[:property_summary] = JSON.parse(row[:property_summary])
        assessment_domain = Domain::Assessment.new(row)

        result << assessment_domain
      end

      result
    end

    def update_field(assessment_id, field, value)
      sql =
        "UPDATE assessments SET " +
        ActiveRecord::Base.connection.quote_column_name(field) +
        " = '" +
        ActiveRecord::Base.sanitize_sql(value) +
        "' WHERE assessment_id = '" +
        ActiveRecord::Base.sanitize_sql(assessment_id) +
        "'"

      Assessment.connection.execute(sql)
    end

  private

    def send_to_db(domestic_energy_assessment)
      existing_assessment =
        Assessment.find_by(
          assessment_id: domestic_energy_assessment.get(:assessment_id),
        )

      if existing_assessment
        existing_assessment.update(domestic_energy_assessment.to_record)

        where_assessment = {
          assessment_id: domestic_energy_assessment.get(:assessment_id),
        }

        DomesticEpcEnergyImprovement.where(where_assessment).delete_all
      else
        Assessment.create(domestic_energy_assessment.to_record)
      end

      improvements =
        domestic_energy_assessment.get(:recommended_improvements).map(
          &:to_record
        )
      improvements.each do |improvement|
        DomesticEpcEnergyImprovement.create(improvement)
      end
    end

    def get_energy_rating_band(number)
      case number
      when 1..20
        "g"
      when 21..38
        "f"
      when 39..54
        "e"
      when 55..68
        "d"
      when 69..80
        "c"
      when 81..91
        "b"
      when 92..100
        "a"
      end
    end
  end
end
