# frozen_string_literal: true

require 'active_support/core_ext/hash/conversions'

module UseCase
  class ValidateAndLodgeAssessment
    class ValidationErrorException < StandardError; end
    class UnauthorisedToLodgeAsThisSchemeException < StandardError; end
    class SchemaNotSupportedException < StandardError; end

    def initialize(
      validate_assessment_use_case,
      lodge_assessment_use_case,
      check_assessor_belongs_to_scheme
    )
      @validate_assessment_use_case = validate_assessment_use_case
      @lodge_assessment_use_case = lodge_assessment_use_case
      @check_assessor_belongs_to_scheme = check_assessor_belongs_to_scheme
    end

    def execute(assessment_id, xml, schema_name, scheme_ids)
      lodgement = Domain::Lodgement.new(xml_to_hash(xml), schema_name)

      raise SchemaNotSupportedException unless lodgement.schema_exists?

      unless @validate_assessment_use_case.execute(xml, lodgement.schema_path)
        raise ValidationErrorException
      end

      unless assessor_can_lodge?(lodgement.fetch_data[:assessor_id], scheme_ids)
        raise UnauthorisedToLodgeAsThisSchemeException
      end

      @lodge_assessment_use_case.execute(lodgement, assessment_id)
    end

    private

    def xml_to_hash(xml)
      Hash.from_xml(xml).deep_symbolize_keys
    end

    def assessor_can_lodge?(scheme_assessor_id, scheme_ids)
      @check_assessor_belongs_to_scheme.execute(scheme_assessor_id, scheme_ids)
    end
  end
end
