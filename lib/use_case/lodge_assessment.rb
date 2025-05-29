# frozen_string_literal: true

module UseCase
  class LodgeAssessment
    class InactiveAssessorException < StandardError
    end

    class AssessmentIdMismatchException < StandardError
    end

    class DuplicateAssessmentIdException < StandardError
    end

    def initialize(
      assessments_gateway:,
      assessments_search_gateway:,
      assessors_gateway:,
      assessments_xml_gateway:,
      assessments_address_id_gateway:,
      related_assessments_gateway:,
      green_deal_plans_gateway:,
      get_canonical_address_id_use_case:,
      event_broadcaster:,
      search_address_gateway:,
      assessments_country_id_gateway:

    )
      @assessments_gateway = assessments_gateway
      @assessments_search_gateway = assessments_search_gateway
      @assessors_gateway = assessors_gateway
      @assessments_xml_gateway = assessments_xml_gateway
      @assessments_address_id_gateway = assessments_address_id_gateway
      @related_assessments_gateway = related_assessments_gateway
      @green_deal_plans_gateway = green_deal_plans_gateway
      @get_canonical_address_id_use_case = get_canonical_address_id_use_case
      @event_broadcaster = event_broadcaster
      @search_address_gateway = search_address_gateway
      @assessments_country_id_gateway = assessments_country_id_gateway
    end

    def execute(data, migrated, schema_name)
      assessment_id = data[:assessment_id]

      if !migrated && find_assessment_by_id(assessment_id)
        raise DuplicateAssessmentIdException
      end

      scheme_assessor_id =
        if data[:assessor_id].nil?
          data[:assessor][:scheme_assessor_id]
        else
          data[:assessor_id]
        end

      assessor = @assessors_gateway.fetch scheme_assessor_id

      check_assessor_qualification data, assessor unless migrated

      assessment =
        Domain::AssessmentIndexRecord.new(
          assessment_id: data[:assessment_id],
          type_of_assessment: data[:type_of_assessment],
          date_of_assessment: data[:date_of_assessment],
          date_registered: data[:date_of_registration],
          date_of_expiry: data[:date_of_expiry],
          assessor:,
          current_energy_efficiency_rating:
            data[:current_energy_efficiency_rating].to_i,
          potential_energy_efficiency_rating:
            data[:potential_energy_efficiency_rating].to_i,
          address_id: data[:address][:address_id] || nil,
          address_line1: data[:address][:address_line1],
          address_line2: data[:address][:address_line2] || "",
          address_line3: data[:address][:address_line3] || "",
          address_line4: data[:address][:address_line4],
          town: data[:address][:town],
          postcode: data[:address][:postcode],
          xml: data[:raw_data],
          migrated:,
          related_rrn: find_related_rrn(data),
          hashed_assessment_id: Helper::RrnHelper.hash_rrn(data[:assessment_id]),
          country_id: data[:country_id],
        )

      if migrated
        @assessments_gateway.insert_or_update assessment
        insert_country_id(data[:assessment_id], data[:country_id], upsert: true)
      else
        begin
          @assessments_gateway.insert assessment
          insert_country_id(data[:assessment_id], data[:country_id])
        rescue Gateway::AssessmentsGateway::AssessmentAlreadyExists
          raise DuplicateAssessmentIdException
        end
      end

      insert_assessment_address_id assessment

      associate_related_green_deals assessment if assessment.type_of_assessment == "RdSAP"

      @assessments_xml_gateway.send_to_db(
        {
          assessment_id: data[:assessment_id],
          xml: data[:raw_data],
          schema_type: schema_name,
        },
      )

      search_address = Domain::SearchAddress.new(data).to_hash
      @search_address_gateway.insert search_address

      @event_broadcaster.broadcast :assessment_lodged, assessment_id: assessment.assessment_id

      assessment
    end

  private

    def check_assessor_qualification(data, assessor)
      active_status = "ACTIVE"

      if data[:type_of_assessment] == "RdSAP" &&
          assessor.domestic_rd_sap_qualification != active_status
        raise InactiveAssessorException
      end

      if data[:type_of_assessment] == "SAP" &&
          assessor.domestic_sap_qualification != active_status
        raise InactiveAssessorException
      end

      if %w[CEPC CEPC-RR].include?(data[:type_of_assessment])
        if data[:building_complexity]
          level = data[:building_complexity]

          if assessor.send(:"non_domestic_nos#{level}_qualification") !=
              active_status
            raise InactiveAssessorException
          end
        end

        if assessor.non_domestic_nos3_qualification != active_status &&
            assessor.non_domestic_nos4_qualification != active_status &&
            assessor.non_domestic_nos5_qualification != active_status
          raise InactiveAssessorException
        end
      end

      if %w[DEC DEC-RR].include?(data[:type_of_assessment]) &&
          assessor.non_domestic_dec_qualification != active_status
        raise InactiveAssessorException
      end

      if %w[AC-CERT AC-REPORT].include?(data[:type_of_assessment]) &&
          assessor.non_domestic_sp3_qualification != active_status &&
          assessor.non_domestic_cc4_qualification != active_status
        raise InactiveAssessorException
      end
    end

    def find_related_rrn(wrapper_hash)
      related_rrn = nil

      # related-rrn: AC-CERT AC-REPORT CEPC DEC-RR
      related_rrn = wrapper_hash[:related_rrn] unless wrapper_hash[:related_rrn]
        .nil?

      # related_certificate: CEPC-RR
      related_rrn = wrapper_hash[:related_certificate] unless wrapper_hash[
        :related_certificate,
      ].nil?

      # administrative_information->related_rrn: DEC
      if related_rrn.nil? &&
          !wrapper_hash.dig(:administrative_information, :related_rrn).nil?
        related_rrn = wrapper_hash[:administrative_information][:related_rrn]
      end
      related_rrn
    end

    def insert_assessment_address_id(assessment)
      canonical_address_id = get_canonical_address_id(assessment)
      source =
        get_assessments_address_id_source(
          lodged_address_id: assessment.address_id,
          canonical_address_id:,
        )

      @assessments_address_id_gateway.send_to_db(
        {
          assessment_id: assessment.assessment_id,
          address_id: canonical_address_id,
          source:,
        },
      )
    end

    def associate_related_green_deals(assessment)
      canonical_address_id = @assessments_address_id_gateway.fetch(assessment.assessment_id)[:address_id]
      related_assessment_ids = @related_assessments_gateway.related_assessment_ids(canonical_address_id).reject { |id| id == assessment.assessment_id }
      green_deal_plan_sets = related_assessment_ids.map { |assessment_id| @green_deal_plans_gateway.fetch assessment_id }
      flat_mapped = green_deal_plan_sets.flat_map(&:itself)
      green_deal_plan_ids = flat_mapped.map(&:green_deal_plan_id).uniq
      green_deal_plan_ids.each do |green_deal_plan_id|
        @green_deal_plans_gateway.link_green_deal_to_assessment green_deal_plan_id, assessment.assessment_id
      end
    rescue StandardError => e
      Logger.new($stdout).error "Associating related green deals for the assessment #{assessment.assessment_id} failed with error #{e.class}, message #{e.message}, backtrace #{e.backtrace.join('; ')}"
    end

    def get_canonical_address_id(assessment)
      @get_canonical_address_id_use_case.execute(
        rrn: assessment.assessment_id,
        related_rrn: assessment.related_rrn,
        address_id: assessment.address_id,
        type_of_assessment: assessment.type_of_assessment,
      )
    end

    def find_assessment_by_id(assessment_id)
      @assessments_search_gateway.search_by_assessment_id(assessment_id, restrictive: false)
        .first
    end

    def get_assessments_address_id_source(
      lodged_address_id:,
      canonical_address_id:
    )
      if lodged_address_id == canonical_address_id
        "lodgement"
      else
        "adjusted_at_lodgement"
      end
    end

    def insert_country_id(assessment_id, country_id = nil, upsert: false)
      @assessments_country_id_gateway.insert(assessment_id:, country_id:, upsert:) unless country_id.nil?
    end
  end
end
