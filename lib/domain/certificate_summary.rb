module Domain
  class CertificateSummary
    def initialize(
      assessment:,
      assessment_id:,
      related_assessments:
    )
      @assessment = assessment
      @assessment_id = assessment_id
      @related_assessments = related_assessments
      @certificate_summary_data = nil

      certificate_summary
      update_address_id
      update_opt_out_status
      update_related_assessments
      update_country_name
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
      @certificate_summary_data = lodged_values.to_certificate_summary
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
        type_of_assessment = @certificate_summary_data[:type_of_assessment]
        related_assessments = Domain::RelatedAssessments.new(assessment_id: @assessment_id,
                                                             type_of_assessment:,
                                                             assessments: @related_assessments)
        @certificate_summary_data[:related_assessments] = related_assessments.assessments
        @certificate_summary_data[:superseded_by] = related_assessments.superseded_by
      end
    end

    # not used for non-dom certs
    def update_country_name
      @certificate_summary_data[:country_name] = @assessment["country_name"]
    end

    # not used for non-dom certs
    def set_assessor; end

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
