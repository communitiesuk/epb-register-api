# frozen_string_literal: true

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

    def execute(assessment_id, xml, schema_name, scheme_ids)
      lodgement = Domain::Lodgement.new(xml_to_hash(xml), schema_name)

      raise SchemaNotSupported unless lodgement.schema_exists?

      unless @validate_lodgement_use_case.execute(xml, lodgement.schema_path)
        raise ValidationError
      end

      unless validate_assessor_can_lodge(
               lodgement.scheme_assessor_id,
               scheme_ids
             )
        raise NotAuthorisedToLodgeAsThisScheme
      end

      @lodge_assessment_use_case.execute(lodgement, assessment_id)
    end

    private

    def xml_to_hash(xml)
      Hash.from_xml(xml).deep_symbolize_keys
    end

    def validate_assessor_can_lodge(scheme_assessor_id, scheme_ids)
      @check_assessor_belongs_to_scheme.execute(scheme_assessor_id, scheme_ids)
    end
  end
end
