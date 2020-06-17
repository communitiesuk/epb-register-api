module Domain
  class SapAssessment
    attr_reader :current_energy_efficiency_rating,
                :potential_energy_efficiency_rating,
                :assessment_id,
                :recommended_improvements,
                :xml,
                :scheme_assessor_id,
                :opt_out

    attr_writer :assessor, :green_deal_plan

    def initialize(
      migrated: nil,
      date_of_assessment: nil,
      date_registered: nil,
      dwelling_type: nil,
      type_of_assessment: nil,
      total_floor_area: nil,
      assessment_id: nil,
      assessor: nil,
      current_energy_efficiency_rating: nil,
      potential_energy_efficiency_rating: nil,
      current_carbon_emission: nil,
      potential_carbon_emission: nil,
      opt_out: false,
      postcode: nil,
      date_of_expiry: nil,
      address_id: nil,
      address_line1: nil,
      address_line2: nil,
      address_line3: nil,
      address_line4: nil,
      town: nil,
      current_space_heating_demand: nil,
      current_water_heating_demand: nil,
      impact_of_loft_insulation: nil,
      impact_of_cavity_insulation: nil,
      impact_of_solid_wall_insulation: nil,
      recommended_improvements: nil,
      property_summary: [],
      related_party_disclosure_number: nil,
      related_party_disclosure_text: nil,
      cancelled_at: nil,
      not_for_issue_at: nil,
      scheme_assessor_id: nil,
      xml: nil
    )
      @migrated = migrated
      @date_of_assessment =
        if !date_of_assessment.nil?
          Date.strptime(date_of_assessment.to_s, "%Y-%m-%d")
        else
          ""
        end
      @date_registered =
        if !date_registered.nil?
          Date.strptime(date_registered.to_s, "%Y-%m-%d")
        else
          ""
        end
      @dwelling_type = dwelling_type
      @type_of_assessment = type_of_assessment
      @total_floor_area = total_floor_area.to_f
      @assessment_id = assessment_id
      @assessor = assessor
      @current_energy_efficiency_rating = current_energy_efficiency_rating
      @potential_energy_efficiency_rating = potential_energy_efficiency_rating
      @current_carbon_emission = current_carbon_emission
      @potential_carbon_emission = potential_carbon_emission
      @opt_out = opt_out
      @postcode = postcode
      @date_of_expiry =
        if !date_of_expiry.nil?
          Date.strptime(date_of_expiry.to_s, "%Y-%m-%d")
        else
          ""
        end
      @address_id = address_id
      @address_line1 = address_line1
      @address_line2 = address_line2
      @address_line3 = address_line3
      @address_line4 = address_line4
      @town = town
      @current_space_heating_demand = current_space_heating_demand.to_f
      @current_water_heating_demand = current_water_heating_demand.to_f
      @impact_of_loft_insulation = impact_of_loft_insulation
      @impact_of_cavity_insulation = impact_of_cavity_insulation
      @impact_of_solid_wall_insulation = impact_of_solid_wall_insulation
      @recommended_improvements = recommended_improvements
      @property_summary = property_summary
      @related_party_disclosure_number = related_party_disclosure_number
      @related_party_disclosure_text = related_party_disclosure_text
      @cancelled_at =
        !cancelled_at.nil? ? Date.strptime(cancelled_at.to_s, "%Y-%m-%d") : nil
      @not_for_issue_at =
        unless not_for_issue_at.nil?
          Date.strptime(not_for_issue_at.to_s, "%Y-%m-%d")
        end
      @scheme_assessor_id = scheme_assessor_id
      @xml = xml
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
      when 92..1_000
        "a"
      end
    end

    def to_hash
      data = {
        date_of_assessment: @date_of_assessment.strftime("%Y-%m-%d"),
        date_registered: @date_registered.strftime("%Y-%m-%d"),
        dwelling_type: @dwelling_type,
        type_of_assessment: @type_of_assessment,
        total_floor_area: @total_floor_area.to_f,
        assessment_id: @assessment_id,
        assessor: @assessor,
        current_energy_efficiency_rating: @current_energy_efficiency_rating,
        potential_energy_efficiency_rating: @potential_energy_efficiency_rating,
        current_carbon_emission: @current_carbon_emission.to_f,
        potential_carbon_emission: @potential_carbon_emission.to_f,
        opt_out: @opt_out,
        postcode: @postcode,
        date_of_expiry: @date_of_expiry.strftime("%Y-%m-%d"),
        address_id: @address_id,
        address_line1: @address_line1,
        address_line2: @address_line2,
        address_line3: @address_line3,
        address_line4: @address_line4,
        town: @town,
        heat_demand: {
          current_space_heating_demand: @current_space_heating_demand.to_f,
          current_water_heating_demand: @current_water_heating_demand.to_f,
          impact_of_loft_insulation: @impact_of_loft_insulation,
          impact_of_cavity_insulation: @impact_of_cavity_insulation,
          impact_of_solid_wall_insulation: @impact_of_solid_wall_insulation,
        },
        current_energy_efficiency_band:
          get_energy_rating_band(@current_energy_efficiency_rating),
        potential_energy_efficiency_band:
          get_energy_rating_band(@potential_energy_efficiency_rating),
        recommended_improvements: @recommended_improvements.map(&:to_hash),
        property_summary: @property_summary,
        related_party_disclosure_number: @related_party_disclosure_number,
        related_party_disclosure_text: @related_party_disclosure_text,
      }

      data[:green_deal_plan] = @green_deal_plan if @green_deal_plan

      data[:status] =
        if !@cancelled_at.nil?
          "CANCELLED"
        elsif !@not_for_issue_at.nil?
          "NOT_FOR_ISSUE"
        elsif @date_of_expiry < Time.now
          "EXPIRED"
        else
          "ENTERED"
        end

      data
    end

    def to_record
      {
        migrated: @migrated,
        date_of_assessment: @date_of_assessment,
        date_registered: @date_registered,
        dwelling_type: @dwelling_type,
        type_of_assessment: @type_of_assessment,
        total_floor_area: @total_floor_area.to_f,
        assessment_id: @assessment_id,
        scheme_assessor_id: @assessor.scheme_assessor_id,
        current_energy_efficiency_rating:
          @current_energy_efficiency_rating.to_f,
        potential_energy_efficiency_rating:
          @potential_energy_efficiency_rating.to_f,
        current_carbon_emission: @current_carbon_emission.to_f,
        potential_carbon_emission: @potential_carbon_emission.to_f,
        opt_out: @opt_out,
        postcode: @postcode,
        date_of_expiry: @date_of_expiry,
        address_id: @address_id,
        address_line1: @address_line1,
        address_line2: @address_line2,
        address_line3: @address_line3,
        address_line4: @address_line4,
        town: @town,
        current_space_heating_demand: @current_space_heating_demand,
        current_water_heating_demand: @current_water_heating_demand,
        impact_of_loft_insulation: @impact_of_loft_insulation,
        impact_of_cavity_insulation: @impact_of_cavity_insulation,
        impact_of_solid_wall_insulation: @impact_of_solid_wall_insulation,
        property_summary: @property_summary,
        related_party_disclosure_number: @related_party_disclosure_number,
        related_party_disclosure_text: @related_party_disclosure_text,
      }
    end
  end
end
