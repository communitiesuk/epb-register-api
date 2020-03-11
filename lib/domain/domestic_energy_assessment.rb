module Domain
  class DomesticEnergyAssessment

    attr_reader :current_energy_efficiency_rating, :potential_energy_efficiency_rating, :assessment_id


    def initialize(
        date_of_assessment,
        date_registered,
        dwelling_type,
        type_of_assessment,
        total_floor_area,
        assessment_id,
        scheme_assessor_id,
        address_summary,
        current_energy_efficiency_rating,
        potential_energy_efficiency_rating,
        postcode,
        date_of_expiry,
        address_line1,
        address_line2,
        address_line3,
        address_line4,
        town
      )
      @date_of_assessment = Date.strptime(date_of_assessment, '%Y-%m-%d')
      @date_registered = Date.strptime(date_registered, '%Y-%m-%d')
      @dwelling_type = dwelling_type
      @type_of_assessment = type_of_assessment
      @total_floor_area = total_floor_area
      @assessment_id = assessment_id
      @scheme_assessor_id = scheme_assessor_id
      @address_summary = address_summary
      @current_energy_efficiency_rating = current_energy_efficiency_rating
      @potential_energy_efficiency_rating = potential_energy_efficiency_rating
      @postcode = postcode
      @date_of_expiry = Date.strptime(date_of_expiry, '%Y-%m-%d')
      @address_line1 = address_line1
      @address_line2 = address_line2
      @address_line3 = address_line3
      @address_line4 = address_line4
      @town = town
    end

    def get_energy_rating_band(number)
      case number
      when 1..20
        'g'
      when 21..38
        'f'
      when 39..54
        'e'
      when 55..68
        'd'
      when 69..80
        'c'
      when 81..91
        'b'
      when 92..100
        'a'
      end
    end

    def to_hash
      {
          date_of_assessment:
              @date_of_assessment.strftime('%Y-%m-%d'),
          date_registered: @date_registered.strftime('%Y-%m-%d'),
          dwelling_type: @dwelling_type,
          type_of_assessment: @type_of_assessment,
          total_floor_area: @total_floor_area,
          assessment_id: @assessment_id,
          scheme_assessor_id: @scheme_assessor_id,
          address_summary: @address_summary,
          current_energy_efficiency_rating:
              @current_energy_efficiency_rating,
          potential_energy_efficiency_rating:
              @potential_energy_efficiency_rating,
          postcode: @postcode,
          date_of_expiry: @date_of_expiry.strftime('%Y-%m-%d'),
          address_line1: @address_line1,
          address_line2: @address_line2,
          address_line3: @address_line3,
          address_line4: @address_line4,
          town: @town,
          current_energy_efficiency_band:
              get_energy_rating_band(@current_energy_efficiency_rating),
          potential_energy_efficiency_band:
              get_energy_rating_band(
                  @potential_energy_efficiency_rating
              )
      }
    end

    def to_record
      {
          date_of_assessment:
              @date_of_assessment,
          date_registered: @date_registered,
          dwelling_type: @dwelling_type,
          type_of_assessment: @type_of_assessment,
          total_floor_area: @total_floor_area,
          assessment_id: @assessment_id,
          scheme_assessor_id: @scheme_assessor_id,
          address_summary: @address_summary,
          current_energy_efficiency_rating:
              @current_energy_efficiency_rating,
          potential_energy_efficiency_rating:
              @potential_energy_efficiency_rating,
          postcode: @postcode,
          date_of_expiry: @date_of_expiry,
          address_line1: @address_line1,
          address_line2: @address_line2,
          address_line3: @address_line3,
          address_line4: @address_line4,
          town: @town,
      }
    end
  end
end
