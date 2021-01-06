module UseCase
  module AssessmentSummary
    class Supplement
      def registered_by!(hash)
        assessor_id = hash[:assessor][:scheme_assessor_id]
        assessor = Gateway::AssessorsGateway.new.fetch(assessor_id).to_hash

        hash[:assessor][:registered_by] = {
          name: assessor[:registered_by][:name],
          scheme_id: assessor[:registered_by][:scheme_id],
        }

        if hash.dig(:assessor, :contact_details, :email).blank?
          hash[:assessor][:contact_details][:email] =
            assessor[:contact_details][:email]
        end

        if hash.dig(:assessor, :contact_details, :telephone).blank?
          hash[:assessor][:contact_details][:telephone] =
            assessor[:contact_details][:telephone_number]
        end
      end

      def set_assessor!(hash)
        assessor_id = hash[:assessor][:scheme_assessor_id]
        assessor = Gateway::AssessorsGateway.new.fetch(assessor_id)&.to_hash

        unless hash.dig(:assessor, :contact_details, :email).blank?
          assessor[:contact_details][:email] =
            hash.dig(:assessor, :contact_details, :email)
        end

        unless hash.dig(:assessor, :contact_details, :telephone).blank?
          assessor[:contact_details][:telephone_number] =
            hash.dig(:assessor, :contact_details, :telephone)
        end

        hash[:assessor] = assessor
      end

      def add_green_deal!(hash)
        assessment_id = hash[:assessment_id]

        hash[:green_deal_plan] =
          Gateway::GreenDealPlansGateway.new.fetch(assessment_id)
      end

      def related_assessments!(hash)
        related_assessments =
          Gateway::RelatedAssessmentsGateway.new.by_address_id hash[:address_id]

        other_assessments_without_self =
          related_assessments.filter do |assessment|
            related = assessment.to_hash

            related[:assessment_type] == hash[:type_of_assessment] &&
              related[:assessment_id] != hash[:assessment_id]
          end

        hash[:related_assessments] = other_assessments_without_self
      end
    end
  end
end
