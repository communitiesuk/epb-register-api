# frozen_string_literal: true

module UseCase
  class ValidateAndLodgeAssessment
    class ValidationErrorException < StandardError; end
    class UnauthorisedToLodgeAsThisSchemeException < StandardError; end
    class SchemaNotSupportedException < StandardError; end
    class SchemaNotDefined < StandardError; end

    def initialize(
      validate_assessment_use_case,
      lodge_assessment_use_case,
      check_assessor_belongs_to_scheme_use_case
    )
      @validate_assessment_use_case = validate_assessment_use_case
      @lodge_assessment_use_case = lodge_assessment_use_case
      @check_assessor_belongs_to_scheme_use_case =
        check_assessor_belongs_to_scheme_use_case
    end

    def execute(xml, schema_name, scheme_ids, migrated)
      raise SchemaNotDefined unless schema_name

      lodgement = Domain::Lodgement.new(xml, schema_name)

      unless Helper::SchemaListHelper.new(schema_name).schema_exists?
        raise SchemaNotSupportedException
      end

      unless @validate_assessment_use_case.execute(
        xml,
        Helper::SchemaListHelper.new(schema_name).schema_path,
      )
        raise ValidationErrorException
      end

      responses = []

      ActiveRecord::Base.transaction do
        lodgement.fetch_data.each do |lodgement_data|
          unless assessor_can_lodge?(lodgement_data[:assessor_id], scheme_ids)
            raise UnauthorisedToLodgeAsThisSchemeException
          end

          responses.push(@lodge_assessment_use_case.execute(lodgement_data, migrated))
        end
      end

      responses
    end

  private

    def assessor_can_lodge?(scheme_assessor_id, scheme_ids)
      @check_assessor_belongs_to_scheme_use_case.execute(
        scheme_assessor_id,
        scheme_ids,
      )
    end
  end
end
