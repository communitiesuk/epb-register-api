require 'active_support/core_ext/hash/conversions'

module UseCase
  class ValidateAndLodgeAssessment
    class ValidationError < StandardError; end

    def initialize(validate_lodgement_use_case, lodge_assessment_use_case)
      @validate_lodgement_use_case = validate_lodgement_use_case
      @lodge_assessment_use_case = lodge_assessment_use_case
    end

    def execute(assessment_id, xml, content_type)
      unless @validate_lodgement_use_case.execute(xml, content_type)
        raise ValidationError
      end

      hash = xml_to_hash(xml)

      @lodge_assessment_use_case.execute(hash, assessment_id)
    end

    private

    def xml_to_hash(xml)
      Hash.from_xml(xml).deep_symbolize_keys
    end
  end
end
