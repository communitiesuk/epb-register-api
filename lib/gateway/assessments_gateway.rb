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

    def search_by_postcode(postcode, assessment_types = [])
      sanitized_assessment_types =
        assessment_types.map do |assessment_type|
          ActiveRecord::Base.sanitize_sql(assessment_type)
        end

      sql =
        "SELECT
            scheme_assessor_id, assessment_id, date_of_assessment, date_registered, dwelling_type,
            type_of_assessment, total_floor_area, current_energy_efficiency_rating,
            potential_energy_efficiency_rating, opt_out, postcode, date_of_expiry,
            address_line1, address_line2, address_line3, address_line4, town,
            current_space_heating_demand, current_water_heating_demand, impact_of_loft_insulation,
            impact_of_cavity_insulation, impact_of_solid_wall_insulation, tenure, property_age_band,
            current_carbon_emission, potential_carbon_emission, property_summary, related_party_disclosure_number,
            related_party_disclosure_text, cancelled_at, not_for_issue_at, lighting_cost_current,
          heating_cost_current, hot_water_cost_current, lighting_cost_potential, heating_cost_potential, hot_water_cost_potential
        FROM assessments
        WHERE postcode = '#{
          ActiveRecord::Base.sanitize_sql(postcode)
        }' AND type_of_assessment IN('" +
        sanitized_assessment_types.join("', '") +
        "')
AND cancelled_at IS NULL
AND not_for_issue_at IS NULL
AND opt_out = false"
      response = Assessment.connection.execute(sql)
      result = []

      response.each { |row| result << row_to_domain(row) }

      result
    end

    def search_by_assessment_id(
      assessment_id, restrictive = true, assessment_type = []
    )
      sql =
        "SELECT
          scheme_assessor_id, assessment_id, date_of_assessment, date_registered, dwelling_type,
          type_of_assessment, total_floor_area, current_energy_efficiency_rating,
          potential_energy_efficiency_rating, opt_out, postcode, date_of_expiry,
          address_line1, address_line2, address_line3, address_line4, town,
          current_space_heating_demand, current_water_heating_demand, impact_of_loft_insulation,
          impact_of_cavity_insulation, impact_of_solid_wall_insulation, tenure, property_age_band,
          current_carbon_emission, potential_carbon_emission, property_summary, related_party_disclosure_number,
          related_party_disclosure_text, cancelled_at, not_for_issue_at, address_id, lighting_cost_current,
          heating_cost_current, hot_water_cost_current, lighting_cost_potential, heating_cost_potential, hot_water_cost_potential
        FROM assessments
        WHERE assessment_id = '#{
          ActiveRecord::Base.sanitize_sql(assessment_id)
        }'"

      if restrictive
        sql += " AND cancelled_at IS NULL"
        sql += " AND not_for_issue_at IS NULL"
      end

      unless assessment_type.empty?
        ins = []
        assessment_type.each do |type|
          ins.push("'" + ActiveRecord::Base.sanitize_sql(type) + "'")
        end
        sql += " AND type_of_assessment IN(" + ins.join(", ") + ")"
      end

      response = Assessment.connection.execute(sql)

      result = []
      response.each do |row|
        assessment_domain = row_to_domain(row)

        improvement_records =
          DomesticEpcEnergyImprovement.where(assessment_id: assessment_id)
        improvements =
          improvement_records.map { |i| row_to_energy_improvement(i).to_hash }

        assessment_domain.set(:recommended_improvements, improvements)

        result << assessment_domain
      end

      result
    end

    def search_by_street_name_and_town(street_name, town, restrictive = true)
      sql =
        "SELECT
          scheme_assessor_id, assessment_id, date_of_assessment, date_registered, dwelling_type,
          type_of_assessment, total_floor_area, current_energy_efficiency_rating,
          potential_energy_efficiency_rating, opt_out, postcode, date_of_expiry,
          address_line1, address_line2, address_line3, address_line4, town,
          current_space_heating_demand, current_water_heating_demand, impact_of_loft_insulation,
          impact_of_cavity_insulation, impact_of_solid_wall_insulation, tenure, property_age_band,
          current_carbon_emission, potential_carbon_emission, property_summary, related_party_disclosure_number,
          related_party_disclosure_text, cancelled_at, not_for_issue_at, lighting_cost_current,
          heating_cost_current, hot_water_cost_current, lighting_cost_potential, heating_cost_potential, hot_water_cost_potential
        FROM assessments
        WHERE (address_line1 ILIKE '%#{
          ActiveRecord::Base.sanitize_sql(street_name)
        }' OR address_line2 ILIKE '%#{
          ActiveRecord::Base.sanitize_sql(street_name)
        }' OR address_line3 ILIKE '%#{
          ActiveRecord::Base.sanitize_sql(street_name)
        }') AND (town ILIKE '#{ActiveRecord::Base.sanitize_sql(town)}')
         AND type_of_assessment IN('RdSAP', 'SAP')"

      if restrictive
        sql += " AND cancelled_at IS NULL"
        sql += " AND not_for_issue_at IS NULL"
        sql += " AND opt_out = false"
      end

      response = Assessment.connection.execute(sql)

      result = []
      response.each { |row| result << row_to_domain(row) }

      result
    end

    def update_field(assessment_id, field, value)
      sql =
        "UPDATE assessments SET " +
        ActiveRecord::Base.connection.quote_column_name(field) + " = '" +
        ActiveRecord::Base.sanitize_sql(value) + "' WHERE assessment_id = '" +
        ActiveRecord::Base.sanitize_sql(assessment_id) + "'"

      Assessment.connection.execute(sql)
    end

  private

    def send_to_db(domestic_energy_assessment)
      ActiveRecord::Base.transaction do
        existing_assessment =
          Assessment.find_by(
            assessment_id: domestic_energy_assessment.get(:assessment_id),
          )

        if existing_assessment
          delete_assessment = <<-SQL
            DELETE FROM assessments WHERE assessment_id = $1
          SQL

          delete_xml = <<-SQL
            DELETE FROM assessments_xml WHERE assessment_id = $1
          SQL

          delete_improvements = <<-SQL
            DELETE FROM domestic_epc_energy_improvements WHERE assessment_id = $1
          SQL

          binds = [
            ActiveRecord::Relation::QueryAttribute.new(
              "id",
              domestic_energy_assessment.get(:assessment_id),
              ActiveRecord::Type::String.new,
            ),
          ]

          ActiveRecord::Base.connection.exec_query delete_xml, "SQL", binds

          ActiveRecord::Base.connection.exec_query delete_improvements,
                                                   "SQL",
                                                   binds

          ActiveRecord::Base.connection.exec_query delete_assessment,
                                                   "SQL",
                                                   binds
        end

        Assessment.create domestic_energy_assessment.to_record

        improvements =
          domestic_energy_assessment.get(:recommended_improvements).map(
            &:to_record
          )

        improvements.each do |improvement|
          DomesticEpcEnergyImprovement.create improvement
        end
      end
    end

    def row_to_domain(row)
      row.symbolize_keys!
      row[:property_summary] = JSON.parse(row[:property_summary])
      lighting_cost_current = row.delete(:lighting_cost_current)
      heating_cost_current = row.delete(:heating_cost_current)
      hot_water_cost_current = row.delete(:hot_water_cost_current)
      lighting_cost_potential = row.delete(:lighting_cost_potential)
      heating_cost_potential = row.delete(:heating_cost_potential)
      hot_water_cost_potential = row.delete(:hot_water_cost_potential)
      domain = Domain::Assessment.new(row)

      if domain.is_type?(Domain::RdsapAssessment) ||
          domain.is_type?(Domain::SapAssessment)
        domain.set(:lighting_cost_current, lighting_cost_current)
        domain.set(:heating_cost_current, heating_cost_current)
        domain.set(:hot_water_cost_current, hot_water_cost_current)
        domain.set(:lighting_cost_potential, lighting_cost_potential)
        domain.set(:heating_cost_potential, heating_cost_potential)
        domain.set(:hot_water_cost_potential, hot_water_cost_potential)
      end

      domain
    end
  end
end
