module UseCase
  class FetchRenewableHeatIncentive
    class NotFoundException < StandardError
    end

    class AssessmentGone < StandardError
    end

    def initialize
      @renewable_heat_incentive_gateway =
        Gateway::RenewableHeatIncentiveGateway.new
      @assessments_address_id_gateway = Gateway::AssessmentsAddressIdGateway.new
      @related_assessments_gateway = Gateway::RelatedAssessmentsGateway.new
    end

    def execute(assessment_id)
      # This endpoint returns details of the most recent assessment for the
      # property, which might not be the assessment_id originally requested.

      canonical_address_record =
        @assessments_address_id_gateway.fetch(assessment_id)
    rescue ActiveRecord::RecordNotFound
      raise NotFoundException
    else
      canonical_address_id = canonical_address_record[:address_id]
      related_assessments =
        @related_assessments_gateway.by_address_id canonical_address_id

      # We already know there is a record for the assessment_id, so the only way
      # related_assessments is empty is if all certificates for that address
      # are cancelled or not for issue
      raise AssessmentGone unless related_assessments.first

      latest_assessment_id = related_assessments.first.to_hash[:assessment_id]

      renewable_heat_incentive =
        @renewable_heat_incentive_gateway.fetch latest_assessment_id
      raise NotFoundException unless renewable_heat_incentive

      renewable_heat_incentive = renewable_heat_incentive.to_hash
      raise AssessmentGone if renewable_heat_incentive.delete :is_cancelled

      renewable_heat_incentive
    end
  end
end
