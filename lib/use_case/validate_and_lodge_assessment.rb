# frozen_string_literal: true

module UseCase
  class ValidateAndLodgeAssessment
    class OverriddenLodgementEvent < ActiveRecord::Base; end

    class ValidationErrorException < StandardError; end

    class UnauthorisedToLodgeAsThisSchemeException < StandardError; end

    class SchemaNotSupportedException < StandardError; end

    class SupersededSchemaException < SchemaNotSupportedException; end

    class RelatedReportError < StandardError; end

    class AddressIdsDoNotMatch < StandardError; end

    class SchemaNotDefined < StandardError; end

    class SoftwareNotApprovedError < StandardError; end

    class NiAssessmentInvalidPostcode < StandardError; end

    class InvalidSapDataVersionError < StandardError
      attr_reader :schema_name, :failed_node, :invalid_version_value

      def initialize(schema_name:, failed_node:, invalid_version_value:)
        @schema_name = schema_name
        @failed_node = failed_node
        @invalid_version_value = invalid_version_value
        super("The node #{failed_node} has an invalid version #{invalid_version_value} for the schema #{schema_name}")
      end
    end

    class LodgementFailsCountryConstraintError < StandardError; end

    class LodgementRulesException < StandardError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
        super
      end
    end

    class NotOverridableLodgementRuleError < StandardError; end

    LATEST_COMMERCIAL = %w[CEPC-8.0.0 CEPC-NI-8.0.0].freeze
    LATEST_DOM_EW = %w[SAP-Schema-18.0.0 RdSAP-Schema-20.0.0].freeze
    LATEST_DOM_NI = %w[SAP-Schema-NI-18.0.0 RdSAP-Schema-NI-20.0.0].freeze
    NOT_OVERRIDABLE_LODGEMENT_RULES = %w[
      FLOOR_AREA_CANT_BE_LESS_THAN_ZERO
      DATES_CANT_BE_IN_FUTURE
      DATES_IN_RANGE
      INSPECTION_DATE_LATER_THAN_COMPLETION_DATE
      COMPLETION_DATE_LATER_THAN_REGISTRATION_DATE
      INSPECTION_DATE_LATER_THAN_REGISTRATION_DATE
    ].freeze
    VALID_SAP_DATA_VERSIONS = { "SAP-Schema-19.0.0" => {
      "SAP-Version" => %w[10.2],
      "SAP-Data-Version" => %w[10.2],
    } }.freeze

    def initialize(
      validate_assessment_use_case:,
      lodge_assessment_use_case:,
      check_assessor_belongs_to_scheme_use_case:,
      check_approved_software_use_case:
    )
      @validate_assessment_use_case = validate_assessment_use_case
      @lodge_assessment_use_case = lodge_assessment_use_case
      @check_assessor_belongs_to_scheme_use_case = check_assessor_belongs_to_scheme_use_case
      @check_approved_software_use_case = check_approved_software_use_case
    end

    def execute(assessment_xml:, schema_name:, scheme_ids:, migrated:, overridden:)
      raise SchemaNotDefined unless schema_name

      unless Helper::SchemaListHelper.new(schema_name).schema_exists?
        raise SchemaNotSupportedException
      end

      ensure_lodgement_xml_valid assessment_xml, schema_name

      lodgement_data =
        extract_data_from_lodgement_xml Domain::Lodgement.new(assessment_xml, schema_name)

      xml_doc = as_parsed_document assessment_xml

      raise SoftwareNotApprovedError unless migrated || software_is_approved?(
        assessment_xml_doc: xml_doc,
        schema_name:,
      )
      raise RelatedReportError unless reports_refer_to_each_other?(xml_doc)
      raise AddressIdsDoNotMatch unless address_ids_match?(lodgement_data)

      ensure_sap_data_version_valid(assessment_xml_doc: xml_doc, schema_name:)

      begin
        LodgementRules::NiCommon.new.validate(schema_name:, address: lodgement_data[0][:address], migrated:)
      rescue Boundary::InvalidNiAssessment => e
        raise LodgementRulesException, e
      end

      wrapper = ViewModel::Factory.new.create(assessment_xml, schema_name, false)
      schema_valid = UseCase::CheckSchemaVersion.new.execute(schema_name)

      unless migrated
        if schema_valid && !wrapper.nil?
          rules =
            if LATEST_COMMERCIAL.include? schema_name
              LodgementRules::NonDomestic.new
            else
              LodgementRules::DomesticCommon.new
            end

          validation_result = rules.validate(wrapper.get_view_model)

          unless validation_result.empty?
            if overridden
              validation_result_codes = validation_result.map { |result| result[:code] }

              unless (validation_result_codes & NOT_OVERRIDABLE_LODGEMENT_RULES).empty?
                error_message = validation_result.select { |error| NOT_OVERRIDABLE_LODGEMENT_RULES.include?(error[:code]) }
                                                 .map { |non_overridable_error| non_overridable_error[:title] }.join(",")
                raise NotOverridableLodgementRuleError, error_message
              end

              lodgement_data.each do |lodgement|
                Gateway::OverriddenLodgmentEventsGateway.new.add(
                  lodgement[:assessment_id],
                  validation_result,
                )
              end
            else
              raise LodgementRulesException, validation_result
            end
          end
        else
          raise SchemaNotSupportedException
        end

      end

      responses = []

      ActiveRecord::Base.transaction do
        lodgement_data.each do |assessment_data|
          unless assessor_can_lodge?(
            assessment_data[:assessor][:scheme_assessor_id],
            scheme_ids,
          )
            raise UnauthorisedToLodgeAsThisSchemeException
          end

          responses.push(
            @lodge_assessment_use_case.execute(
              assessment_data,
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

    def address_ids_match?(lodgement)
      lodgement.map { |assessment| assessment[:address][:address_id] }.uniq
        .length <= 1
    end

    def reports_refer_to_each_other?(xml)
      reports = xml.search("Report")

      if reports.count == 2
        report1 = reports[0]
        report2 = reports[1]

        assessment_id1 = report1.at("RRN").content
        assessment_id2 = report2.at("RRN").content

        related_assessment_id1 = report1.at("Related-RRN").content
        related_assessment_id2 = report2.at("Related-RRN").content

        assessment_id1 == related_assessment_id2 &&
          assessment_id2 == related_assessment_id1
      else
        true
      end
    end

    def software_is_approved?(assessment_xml_doc:, schema_name:)
      @check_approved_software_use_case.execute assessment_xml: assessment_xml_doc,
                                                schema_name:
    end

    def ensure_lodgement_xml_valid(xml, schema_name)
      unless @validate_assessment_use_case.execute(
        xml,
        Helper::SchemaListHelper.new(schema_name).schema_path,
      )
        raise ValidationErrorException
      end
    end

    def ensure_sap_data_version_valid(assessment_xml_doc:, schema_name:)
      return unless schema_name.start_with?("SAP") && VALID_SAP_DATA_VERSIONS.key?(schema_name)

      VALID_SAP_DATA_VERSIONS[schema_name].each do |node, allowed_versions|
        version_value = assessment_xml_doc.at(node).content
        next if allowed_versions.include?(version_value)

        raise InvalidSapDataVersionError.new(
          schema_name:,
          failed_node: node,
          invalid_version_value: version_value,
        )
      end
    end

    def extract_data_from_lodgement_xml(lodgement)
      lodgement.fetch_data
    end

    def as_parsed_document(xml)
      xml_doc = Nokogiri.XML xml
      xml_doc.remove_namespaces!
      xml_doc
    end
  end
end
