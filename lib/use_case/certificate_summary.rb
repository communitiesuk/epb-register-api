module UseCase
  module CertificateSummary
    class Fetch

      class AssessmentUnavailable < StandardError; end
      class NotFoundException < AssessmentUnavailable; end
      class AssessmentGone < AssessmentUnavailable; end

      def initialize(certificate_summary_gateway: nil, green_deal_plans_gateway: nil, related_assessments: nil)
        @certificate_summary_gateway = certificate_summary_gateway || Gateway::CertificateSummaryGateway.new
        @green_deal_plans_gateway = green_deal_plans_gateway || Gateway::GreenDealPlansGateway.new
        @related_assessments = related_assessments || Gateway::RelatedAssessmentsGateway.new
      end

      def execute(assessment_id)
        assessment_id = Helper::RrnHelper.normalise_rrn_format(assessment_id)
        assessment =
          @certificate_summary_gateway
            .fetch(assessment_id).to_hash

        if assessment
          if assessment["not_for_issue_at"] != nil || assessment["cancelled_at"] != nil
            raise AssessmentGone
          end
        else
          raise NotFoundException
        end

        unless assessment["green_deal_plan_id"] == nil
          green_deal_plan = @green_deal_plans_gateway.fetch(assessment_id)
          assessment["green_deal_plan"] = green_deal_plan
        end
        assessment
      end
    end
  end
end
