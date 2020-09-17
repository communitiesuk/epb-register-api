module Domain
  class AssessmentSearchResult
    def initialize(
      migrated: nil,
      type_of_assessment: nil,
      assessment_id: nil,
      current_energy_efficiency_rating: nil,
      opt_out: false,
      postcode: nil,
      date_of_expiry: nil,
      date_registered: nil,
      address_id: nil,
      address_line1: nil,
      address_line2: nil,
      address_line3: nil,
      address_line4: nil,
      town: nil,
      cancelled_at: nil,
      not_for_issue_at: nil,
      date_of_assessment: nil,
      scheme_assessor_id: nil
    )
      @migrated = migrated
      @date_of_assessment =
        if !date_of_assessment.nil?
          Date.strptime(date_of_assessment.to_s, "%Y-%m-%d")
        else
          ""
        end
      @type_of_assessment = type_of_assessment
      @assessment_id = assessment_id
      @scheme_assessor_id = scheme_assessor_id
      @opt_out = opt_out
      @current_energy_efficiency_rating = current_energy_efficiency_rating
      @postcode = postcode
      @date_registered = date_registered
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
      @cancelled_at =
        (Date.strptime(cancelled_at.to_s, "%Y-%m-%d") unless cancelled_at.nil?)
      @not_for_issue_at =
        unless not_for_issue_at.nil?
          Date.strptime(not_for_issue_at.to_s, "%Y-%m-%d")
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
      when 92..1_000
        "a"
      end
    end

    def to_hash
      expiry_helper = Gateway::AssessmentExpiryHelper.new(@cancelled_at, @not_for_issue_at, @date_of_expiry)
      {
        date_of_assessment: @date_of_assessment.strftime("%Y-%m-%d"),
        type_of_assessment: @type_of_assessment,
        assessment_id: @assessment_id,
        current_energy_efficiency_rating: @current_energy_efficiency_rating,
        opt_out: @opt_out,
        postcode: @postcode,
        date_of_expiry: @date_of_expiry.strftime("%Y-%m-%d"),
        address_id: @address_id,
        address_line1: @address_line1,
        address_line2: @address_line2,
        address_line3: @address_line3,
        address_line4: @address_line4,
        town: @town,
        current_energy_efficiency_band:
          get_energy_rating_band(@current_energy_efficiency_rating),
        status: expiry_helper.assessment_status
      }
    end

    def get(key)
      instance_variable_get "@#{key}"
    end

    def set(key, value)
      instance_variable_set "@#{key}", value
    end
  end
end
