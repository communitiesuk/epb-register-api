# frozen_string_literal: true

module UseCase
  class ValidateAndLodgeAssessment
    class OveriddenLodgementEvent < ActiveRecord::Base
    end
    class ValidationErrorException < StandardError
    end
    class UnauthorisedToLodgeAsThisSchemeException < StandardError
    end
    class SchemaNotSupportedException < StandardError
    end
    class RelatedReportError < StandardError
    end
    class AddressIdsDoNotMatch < StandardError
    end
    class NonexistentUprn < StandardError
    end
    class SchemaNotDefined < StandardError
    end
    class LodgementRulesException < StandardError
      attr_reader :errors
      def initialize(errors)
        @errors = errors
      end
    end

    LATEST_COMMERCIAL = %w[CEPC-8.0.0 CEPC-NI-8.0.0].freeze
    LATEST_DOM_EW = %w[SAP-Schema-18.0.0 RdSAP-Schema-20.0.0].freeze
    LATEST_DOM_NI = %w[SAP-Schema-NI-18.0.0 RdSAP-Schema-NI-20.0.0].freeze

    def initialize
      @validate_assessment_use_case = UseCase::ValidateAssessment.new
      @lodge_assessment_use_case = UseCase::LodgeAssessment.new
      @check_assessor_belongs_to_scheme_use_case =
        UseCase::CheckAssessorBelongsToScheme.new
    end

    def execute(xml, schema_name, scheme_ids, migrated, overidden)
      raise SchemaNotDefined unless schema_name

      unless Helper::SchemaListHelper.new(schema_name).schema_exists?
        raise SchemaNotSupportedException
      end

      ensure_lodgement_xml_valid xml, schema_name

      lodgement_data =
        extract_data_from_lodgement_xml Domain::Lodgement.new(xml, schema_name)

      raise RelatedReportError unless reports_refer_to_each_other?(xml)
      raise AddressIdsDoNotMatch unless address_ids_match?(lodgement_data)

      ensure_uprns_exist lodgement_data

      unless migrated
        wrapper = ViewModel::Factory.new.create(xml, schema_name, false)
        if (
             (
               LATEST_COMMERCIAL + LATEST_DOM_EW + LATEST_DOM_NI
             ).include? schema_name
           ) && !wrapper.nil?
          rules =
            if LATEST_COMMERCIAL.include? schema_name
              LodgementRules::NonDomestic.new
            else
              LodgementRules::DomesticCommon.new
            end

          validation_result = rules.validate(wrapper.get_view_model)

          unless validation_result.empty?
            if overidden
              lodgement_data.each do |lodgement_data|
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
      xml = Nokogiri.XML(xml)
      xml.remove_namespaces!
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

    def ensure_lodgement_xml_valid(xml, schema_name)
      unless @validate_assessment_use_case.execute(
        xml,
        Helper::SchemaListHelper.new(schema_name).schema_path,
      )
        raise ValidationErrorException
      end
    end

    def extract_data_from_lodgement_xml(lodgement)
      lodgement.fetch_data
    end

    def ensure_uprns_exist(lodgement_data)
      address_ids_from(lodgement_data).each do |address_id|
        return if address_id.nil? || !address_id.start_with?("UPRN-")

        raise NonexistentUprn, "The given UPRN %s does not exist in the AddressBase data set." % address_id unless uprn_exists? address_id[5..-1]
      end
    end

    def uprn_exists?(uprn)
      @address_base_gateway ||= Gateway::AddressBaseSearchGateway.new
      @address_base_gateway.check_uprn_exists(uprn)
    end

    def address_ids_from(lodgement_data)
      lodgement_data.map { |data| data.dig(:address, :address_id) }
    end
  end
end
