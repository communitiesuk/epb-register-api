require 'active_support/core_ext/hash/conversions'

module UseCase
  class ValidateAndLodgeAssessment
    class ValidationError < StandardError; end
    class NotAuthorisedToLodgeAsThisScheme < StandardError; end
    class SchemaNotSupported < StandardError; end

    def initialize(
      validate_lodgement_use_case,
      lodge_assessment_use_case,
      check_assessor_belongs_to_scheme
    )
      @validate_lodgement_use_case = validate_lodgement_use_case
      @lodge_assessment_use_case = lodge_assessment_use_case
      @check_assessor_belongs_to_scheme = check_assessor_belongs_to_scheme
    end

    def execute(assessment_id, xml, content_type, scheme_ids)
      schema_name = content_type.split('+')[1]
      schema_details = schema_settings(schema_name)

      unless @validate_lodgement_use_case.execute(xml, schema_name)
        raise ValidationError
      end

      hash = xml_to_hash(xml)

      unless validate_assessor_can_lodge(hash, scheme_ids)
        raise NotAuthorisedToLodgeAsThisScheme
      end

      @lodge_assessment_use_case.execute(hash, assessment_id, content_type)
    end

    private

    def xml_to_hash(xml)
      Hash.from_xml(xml).deep_symbolize_keys
    end

    def validate_assessor_can_lodge(hash, scheme_ids)
      scheme_assessor_id =
        hash[:RdSAP_Report][:Report_Header][:Energy_Assessor][
          :Identification_Number
        ][
          :Membership_Number
        ]
      @check_assessor_belongs_to_scheme.execute(scheme_assessor_id, scheme_ids)
    end

    def schema_settings(schema_name)
      schema_list = {
        'RdSAP-Schema-19.0' => {
          schema_location: ''
        }
      }

      raise SchemaNotSupported unless schema_list.has_key?(schema_name)

      schema_list[schema_name]
    end
  end
end
