# frozen_string_literal: true

module UseCase
  class ValidateAndLodgeAssessment
    class OveriddenLodgementEvent < ActiveRecord::Base; end
    class ValidationErrorException < StandardError; end
    class UnauthorisedToLodgeAsThisSchemeException < StandardError; end
    class SchemaNotSupportedException < StandardError; end
    class SchemaNotDefined < StandardError; end
    class LodgementRulesException < StandardError
      attr_reader :errors
      def initialize(errors)
        @errors = errors
      end
    end

    def initialize
      @validate_assessment_use_case = UseCase::ValidateAssessment.new
      @lodge_assessment_use_case = UseCase::LodgeAssessment.new
      @check_assessor_belongs_to_scheme_use_case =
        UseCase::CheckAssessorBelongsToScheme.new
    end

    def execute(xml, schema_name, scheme_ids, migrated, overidden)
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

      unless migrated
        if schema_name == "CEPC-8.0.0"
          factory = ViewModel::Factory.new.create(xml, schema_name)

          validation_result =
            LodgementRules::NonDomestic.new.validate(factory.get_view_model)

          unless validation_result.empty?
            if overidden
              lodgement.fetch_data.each do |lodgement_data|
                Gateway::OverridenLodgmentEventsGateway.new.add(
                  lodgement_data[:assessment_id],
                  validation_result,
                )
              end
            else
              raise LodgementRulesException, validation_result
            end
          end
        end
      end

      responses = []

      ActiveRecord::Base.transaction do
        lodgement.fetch_data.each do |lodgement_data|
          unless assessor_can_lodge?(lodgement_data[:assessor_id], scheme_ids)
            raise UnauthorisedToLodgeAsThisSchemeException
          end

          responses.push(
            @lodge_assessment_use_case.execute(
              lodgement_data,
              migrated,
              schema_name,
            ),
          )
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
