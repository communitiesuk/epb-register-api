module UseCase
  module CertificateSummary
    class Fetch
      class AssessmentUnavailable < StandardError; end
      class NotFoundException < AssessmentUnavailable; end
      class AssessmentGone < AssessmentUnavailable; end

      def initialize(certificate_summary_gateway: nil, green_deal_plans_gateway: nil, related_assessments_gateway: nil)
        @certificate_summary_gateway = certificate_summary_gateway || Gateway::CertificateSummaryGateway.new
        @green_deal_plans_gateway = green_deal_plans_gateway || Gateway::GreenDealPlansGateway.new
        @related_assessments_gateway = related_assessments_gateway || Gateway::RelatedAssessmentsGateway.new
      end

      def execute(assessment_id)
        assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)
        assessment =
          @certificate_summary_gateway
            .fetch(assessment_id).to_hash

        schema_type = assessment["schema_type"]

        # placeholder logic until non-dom to_certificate_summary_created
        unless schema_type.start_with?("RdSAP", "SAP")
          raise Boundary::InvalidAssessment, schema_type
        end

        if assessment
          if !assessment["not_for_issue_at"].nil? || !assessment["cancelled_at"].nil?
            raise AssessmentGone
          end
        else
          raise NotFoundException
        end

        related_assessments = if assessment["count_address_id_assessments"] > 1
                                @related_assessments_gateway.by_address_id(assessment_id)
                              else
                                []
                              end

        green_deal_plan = if assessment["green_deal_plan_id"].nil?
                            nil
                          else
                            @green_deal_plans_gateway.fetch(assessment_id)
                          end

        Domain::CertificateSummary.new(assessment:,
                                       assessment_id:,
                                       related_assessments:,
                                       green_deal_plan:).certificate_summary_data
      end
    end
  end
end
