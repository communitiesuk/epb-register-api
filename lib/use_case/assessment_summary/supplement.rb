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

      def set_assessor!(hash, method = "to_hash")
        assessor_id = hash[:assessor][:scheme_assessor_id]
        assessor = Gateway::AssessorsGateway.new.fetch(assessor_id)&.to_hash || { contact_details: {} }

        unless hash.dig(:assessor, :contact_details, :email).blank?
          assessor[:contact_details][:email] =
            hash.dig(:assessor, :contact_details, :email)
        end

        unless hash.dig(:assessor, :contact_details, :telephone).blank?
          assessor[:contact_details][:telephone_number] =
            hash.dig(:assessor, :contact_details, :telephone)
        end

        if method == "to_certificate_summary"
          assessor.delete(:search_results_comparison_postcode)
          assessor.delete(:company_details)
          assessor.delete(:address)
          assessor.delete(:qualifications)
          assessor.delete(:middle_names)
          assessor.delete(:date_of_birth)
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

        filtered_by_types = filter_by_types(hash, related_assessments)
        superseded_by!(hash, filtered_by_types)

        other_assessments_without_self_or_opted_out =
          filtered_by_types.filter do |assessment|
            related = assessment.to_hash
            related[:assessment_id] != hash[:assessment_id] && related[:opt_out] == false
          end
        hash[:related_assessments] = other_assessments_without_self_or_opted_out
      end

      def add_country_name!(hash)
        assessment_id = hash[:assessment_id]
        response = Gateway::AssessmentsCountryIdGateway.new.fetch_country_name(assessment_id)

        unless response.nil?
          hash[:country_name] = response["country_name"]
        end
      end

    private

      def filter_by_types(hash, related_assessments)
        domestic_types = %w[RdSAP SAP]

        related_assessments.filter do |assessment|
          related = assessment.to_hash

          (
            domestic_types.include?(related[:assessment_type]) &&
              domestic_types.include?(hash[:type_of_assessment])
          ) || related[:assessment_type] == hash[:type_of_assessment]
        end
      end

      def superseded_by!(hash, related_assessments)
        hash[:superseded_by] = related_assessments.length.positive? && related_assessments.first.to_hash[:assessment_id] != hash[:assessment_id] ? related_assessments.first.to_hash[:assessment_id] : nil
      end
    end
  end
end
