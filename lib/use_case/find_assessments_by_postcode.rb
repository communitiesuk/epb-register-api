module UseCase
  class FindAssessmentsByPostcode
    class PostcodeNotValid < StandardError; end

    class ParameterMissing < StandardError; end

    class AssessmentTypeNotValid < StandardError; end

    def initialize(assessments_search_gateway: Gateway::AssessmentsSearchGateway.new)
      @assessments_gateway = assessments_search_gateway
    end

    def execute(postcode, assessment_types = [], is_scottish: false)
      postcode&.strip!
      postcode&.upcase!

      raise ParameterMissing if postcode.blank?

      raise PostcodeNotValid unless Helper::ValidatePostcodeHelper.valid_postcode?(postcode)

      postcode = Helper::ValidatePostcodeHelper.format_postcode(postcode)

      result =
        @assessments_gateway.search_by_postcode(postcode, assessment_types, is_scottish: is_scottish)

      Helper::NaturalSort.sort!(result)

      { data: result.map { it.to_hash(is_scottish:) }, searchQuery: postcode }
    rescue Gateway::AssessmentsSearchGateway::InvalidAssessmentType
      raise AssessmentTypeNotValid
    end
  end
end
