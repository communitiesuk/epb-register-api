# frozen_string_literal: true

module Gateway
  class DomesticEnergyAssessmentsGateway
    class DomesticEnergyAssessment < ActiveRecord::Base
      def to_hash
        Gateway::DomesticEnergyAssessmentsGateway.new.to_hash(self)
      end
    end

    class DomesticEpcEnergyImprovement < ActiveRecord::Base; end

    def valid_energy_rating(rating)
      rating.is_a?(Integer) && rating.positive?
    end

    def to_hash(assessment)
      {
        date_of_assessment:
          assessment[:date_of_assessment].strftime("%Y-%m-%d"),
        date_registered: assessment[:date_registered].strftime("%Y-%m-%d"),
        dwelling_type: assessment[:dwelling_type],
        type_of_assessment: assessment[:type_of_assessment],
        total_floor_area: assessment[:total_floor_area].to_f,
        assessment_id: assessment[:assessment_id],
        scheme_assessor_id: assessment[:scheme_assessor_id],
        address_summary: assessment[:address_summary],
        current_energy_efficiency_rating:
          assessment[:current_energy_efficiency_rating],
        potential_energy_efficiency_rating:
          assessment[:potential_energy_efficiency_rating],
        current_carbon_emission: assessment[:current_carbon_emission].to_f,
        potential_carbon_emission: assessment[:potential_carbon_emission].to_f,
        opt_out: assessment[:opt_out],
        postcode: assessment[:postcode],
        date_of_expiry: assessment[:date_of_expiry].strftime("%Y-%m-%d"),
        address_line1: assessment[:address_line1],
        address_line2: assessment[:address_line2],
        address_line3: assessment[:address_line3],
        address_line4: assessment[:address_line4],
        town: assessment[:town],
        heat_demand: {
          current_space_heating_demand:
            assessment[:current_space_heating_demand].to_f,
          current_water_heating_demand:
            assessment[:current_water_heating_demand].to_f,
          impact_of_loft_insulation: assessment[:impact_of_loft_insulation],
          impact_of_cavity_insulation: assessment[:impact_of_cavity_insulation],
          impact_of_solid_wall_insulation:
            assessment[:impact_of_solid_wall_insulation],
        },
        current_energy_efficiency_band:
          get_energy_rating_band(assessment[:current_energy_efficiency_rating]),
        potential_energy_efficiency_band:
          get_energy_rating_band(
            assessment[:potential_energy_efficiency_rating],
          ),
        property_summary: assessment[:property_summary],
        related_party_disclosure_number: assessment[:related_party_disclosure_number],
        related_party_disclosure_text: assessment[:related_party_disclosure_text],
      }
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
        DomesticEnergyAssessment.find_by(assessment_id: assessment_id)

      improvement_records =
        DomesticEpcEnergyImprovement.where(assessment_id: assessment_id)
      improvements =
        improvement_records.map { |i| row_to_energy_improvement(i).to_hash }

      return unless energy_assessment_record

      energy_assessment = energy_assessment_record.to_hash
      energy_assessment[:recommended_improvements] = improvements
      energy_assessment
    end

    def insert_or_update(assessment)
      unless valid_energy_rating(assessment.current_energy_efficiency_rating)
        raise ArgumentError, "Invalid current energy rating"
      end

      unless valid_energy_rating(assessment.potential_energy_efficiency_rating)
        raise ArgumentError, "Invalid potential energy rating"
      end

      send_to_db(assessment)
    end

    def search_by_postcode(postcode)
      sql =
        "SELECT
            scheme_assessor_id, assessment_id, date_of_assessment, date_registered, dwelling_type,
            type_of_assessment, total_floor_area, address_summary, current_energy_efficiency_rating,
            potential_energy_efficiency_rating, opt_out, postcode, date_of_expiry,
            address_line1, address_line2, address_line3, address_line4, town,
            current_space_heating_demand, current_water_heating_demand, impact_of_loft_insulation,
            impact_of_cavity_insulation, impact_of_solid_wall_insulation,
            current_carbon_emission, potential_carbon_emission, property_summary, related_party_disclosure_number,
            related_party_disclosure_text
        FROM domestic_energy_assessments
        WHERE postcode = '#{
          ActiveRecord::Base.sanitize_sql(postcode)
        }'"
      response = DomesticEnergyAssessment.connection.execute(sql)
      result = []
      response.each do |row|
        assessment_hash = to_hash(row.symbolize_keys)

        assessment_hash[:property_summary] = JSON.parse(assessment_hash[:property_summary])

        result << assessment_hash
      end
      result
    end

    def search_by_assessment_id(assessment_id)
      sql =
        "SELECT
          scheme_assessor_id, assessment_id, date_of_assessment, date_registered, dwelling_type,
          type_of_assessment, total_floor_area, address_summary, current_energy_efficiency_rating,
          potential_energy_efficiency_rating, opt_out, postcode, date_of_expiry,
          address_line1, address_line2, address_line3, address_line4, town,
          current_space_heating_demand, current_water_heating_demand, impact_of_loft_insulation,
          impact_of_cavity_insulation, impact_of_solid_wall_insulation,
          current_carbon_emission, potential_carbon_emission, property_summary, related_party_disclosure_number,
           related_party_disclosure_text
          FROM domestic_energy_assessments
        WHERE assessment_id = '#{
          ActiveRecord::Base.sanitize_sql(assessment_id)
        }'"

      response = DomesticEnergyAssessment.connection.execute(sql)

      result = []
      response.each do |row|
        assessment_hash = to_hash(row.symbolize_keys)

        assessment_hash[:property_summary] = JSON.parse(assessment_hash[:property_summary])

        result << assessment_hash
      end

      result
    end

    def search_by_street_name_and_town(street_name, town)
      sql =
        "SELECT
          scheme_assessor_id, assessment_id, date_of_assessment, date_registered, dwelling_type,
          type_of_assessment, total_floor_area, address_summary, current_energy_efficiency_rating,
          potential_energy_efficiency_rating, opt_out, postcode, date_of_expiry,
          address_line1, address_line2, address_line3, address_line4, town,
          current_space_heating_demand, current_water_heating_demand, impact_of_loft_insulation,
          impact_of_cavity_insulation, impact_of_solid_wall_insulation,
          current_carbon_emission, potential_carbon_emission, property_summary, related_party_disclosure_number,
          related_party_disclosure_text
        FROM domestic_energy_assessments
        WHERE (address_line1 ILIKE '%#{
          ActiveRecord::Base.sanitize_sql(street_name)
        }' OR address_line2 ILIKE '%#{
          ActiveRecord::Base.sanitize_sql(street_name)
        }' OR address_line3 ILIKE '%#{
          ActiveRecord::Base.sanitize_sql(street_name)
        }') AND (town ILIKE '#{ActiveRecord::Base.sanitize_sql(town)}')"

      response = DomesticEnergyAssessment.connection.execute(sql)

      result = []
      response.each do |row|
        assessment_hash = to_hash(row.symbolize_keys)

        assessment_hash[:property_summary] = JSON.parse(assessment_hash[:property_summary])

        result << assessment_hash
      end

      result
    end

  private

    def send_to_db(domestic_energy_assessment)
      existing_assessment =
        DomesticEnergyAssessment.find_by(
          assessment_id: domestic_energy_assessment.assessment_id,
        )

      if existing_assessment
        existing_assessment.update(domestic_energy_assessment.to_record)
        where_assessment = [
            "assessment_id = ?",
            domestic_energy_assessment.assessment_id,
        ]
        DomesticEpcEnergyImprovement.where(where_assessment).delete_all
      else
        DomesticEnergyAssessment.create(domestic_energy_assessment.to_record)
      end

      improvements = domestic_energy_assessment.recommended_improvements.map(&:to_record)
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
