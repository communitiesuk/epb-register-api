module Domain
  class CertificateSummary
    def initialize(
      assessment:,
      assessment_id:,
      related_assessments:,
      green_deal_plan:
    )
      @assessment = assessment
      @assessment_id = assessment_id
      @related_assessments = related_assessments
      @green_deal_plan = green_deal_plan
      @certificate_summary_data = nil
      @type_of_assessment = nil

      certificate_summary
      @type_of_assessment = @certificate_summary_data[:type_of_assessment]
      update_address_id
      update_opt_out_status
      update_related_assessments
      update_country_name
      update_assessor

      if @type_of_assessment == "RdSAP"
        update_green_deal
      end
    end

    attr_reader :certificate_summary_data

  private

    def certificate_summary
      lodged_values =
        lodged_values_from_xml(
          @assessment["xml"],
          @assessment["schema_type"],
          @assessment_id,
        )

      @certificate_summary_data = if @assessment["schema_type"].include?("CEPC-S-7.1")
                                    lodged_values.to_certificate_summary_scotland
                                  else
                                    lodged_values.to_certificate_summary
                                  end
    end

    def update_address_id
      @certificate_summary_data[:address_id] = @assessment["assessment_address_id"]
    end

    def update_opt_out_status
      @certificate_summary_data[:opt_out] = @assessment["opt_out"]
    end

    def update_related_assessments
      if @related_assessments.empty?
        @certificate_summary_data[:related_assessments] = []
        @certificate_summary_data[:superseded_by] = nil
      else
        related_assessments = Domain::RelatedAssessments.new(assessment_id: @assessment_id,
                                                             type_of_assessment: @type_of_assessment,
                                                             assessments: @related_assessments)
        @certificate_summary_data[:related_assessments] = related_assessments.assessments
        @certificate_summary_data[:superseded_by] = related_assessments.superseded_by
      end
    end

    # not used for non-dom certs
    def update_country_name
      @certificate_summary_data[:country_name] = @assessment["country_name"]
    end

    # based on the set_assessor method for domestic certs
    # - should be able to use this for non-dom certs

    def update_assessor
      @certificate_summary_data[:assessor][:first_name] = @assessment["assessor_first_name"]
      @certificate_summary_data[:assessor][:last_name] = @assessment["assessor_last_name"]
      @certificate_summary_data[:assessor][:registered_by] = {
        name: @assessment["scheme_name"],
        scheme_id: @assessment["scheme_id"],
      }

      if @certificate_summary_data.dig(:assessor, :contact_details, :email).blank?
        @certificate_summary_data[:assessor][:contact_details][:email] = @assessment["assessor_email"]
      end

      @certificate_summary_data[:assessor][:contact_details][:telephone_number] = if @certificate_summary_data.dig(:assessor, :contact_details, :telephone).blank?
                                                                                    @assessment["assessor_telephone_number"]
                                                                                  else
                                                                                    @certificate_summary_data[:assessor][:contact_details][:telephone]
                                                                                  end

      # view model may not need to return this for domestic certificates
      @certificate_summary_data[:assessor].delete(:name)
      @certificate_summary_data[:assessor][:contact_details].delete(:telephone)
    end

    def update_green_deal
      @certificate_summary_data[:green_deal_plan] = if @green_deal_plan.nil?
                                                      []
                                                    else
                                                      @green_deal_plan
                                                    end
    end

    def lodged_values_from_xml(xml, schema_type, assessment_id)
      view_model =
        ViewModel::Factory.new.create(xml, schema_type, assessment_id)
      unless view_model
        raise ArgumentError,
              "Assessment summary unsupported for this assessment type"
      end
      view_model
    end
  end
end
