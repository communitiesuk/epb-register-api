module Domain
  class CepcRrAssessment
    attr_reader :assessment_id, :xml, :scheme_assessor_id, :opt_out

    attr_writer :assessor, :green_deal_plan

    def initialize(
      migrated: nil,
      date_of_assessment: nil,
      date_registered: nil,
      dwelling_type: nil,
      type_of_assessment: nil,
      assessment_id: nil,
      assessor: nil,
      opt_out: false,
      postcode: nil,
      date_of_expiry: nil,
      address_id: nil,
      address_line1: nil,
      address_line2: nil,
      address_line3: nil,
      address_line4: nil,
      town: nil,
      property_age_band: nil,
      cancelled_at: nil,
      not_for_issue_at: nil,
      scheme_assessor_id: nil,
      xml: nil,
      related_assessments: nil
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
      @assessment_id = assessment_id
      @assessor = assessor
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
      @cancelled_at =
        (Date.strptime(cancelled_at.to_s, "%Y-%m-%d") unless cancelled_at.nil?)
      @not_for_issue_at =
        unless not_for_issue_at.nil?
          Date.strptime(not_for_issue_at.to_s, "%Y-%m-%d")
        end
      @scheme_assessor_id = scheme_assessor_id
      @xml = xml
      @related_assessments = related_assessments
    end

    def to_hash
      {
        date_of_assessment: @date_of_assessment.strftime("%Y-%m-%d"),
        date_registered: @date_registered.strftime("%Y-%m-%d"),
        dwelling_type: @dwelling_type,
        type_of_assessment: @type_of_assessment,
        assessment_id: @assessment_id,
        assessor: @assessor,
        opt_out: @opt_out,
        postcode: @postcode,
        date_of_expiry: @date_of_expiry.strftime("%Y-%m-%d"),
        address_id: @address_id,
        address_line1: @address_line1,
        address_line2: @address_line2,
        address_line3: @address_line3,
        address_line4: @address_line4,
        town: @town,
        related_assessments: @related_assessments,
        status:
          if !@cancelled_at.nil?
            "CANCELLED"
          elsif !@not_for_issue_at.nil?
            "NOT_FOR_ISSUE"
          elsif @date_of_expiry < Time.now
            "EXPIRED"
          else
            "ENTERED"
          end,
      }
    end

    def to_record
      {
        migrated: @migrated,
        date_of_assessment: @date_of_assessment,
        date_registered: @date_registered,
        dwelling_type: @dwelling_type,
        type_of_assessment: @type_of_assessment,
        assessment_id: @assessment_id,
        scheme_assessor_id: @assessor.scheme_assessor_id,
        opt_out: @opt_out,
        postcode: @postcode,
        date_of_expiry: @date_of_expiry,
        address_id: @address_id,
        address_line1: @address_line1,
        address_line2: @address_line2,
        address_line3: @address_line3,
        address_line4: @address_line4,
        town: @town,
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
