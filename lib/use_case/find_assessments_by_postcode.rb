module UseCase
  class FindAssessmentsByPostcode
    class PostcodeNotValid < StandardError; end

    def initialize(assessment_gateway)
      @assessment_gateway = assessment_gateway
    end

    def execute(postcode)
      postcode.upcase!

      postcode = postcode.insert(-4, ' ') if postcode[-4] != ' '

      unless Regexp.new(
               '^[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}$',
               Regexp::IGNORECASE
             )
               .match(postcode)
        raise PostcodeNotValid
      end

      result = @assessment_gateway.search_by_postcode(postcode)
      opt_out_filtered_results = []

      result.each do |r|
        opt_out_filtered_results << r unless r[:opt_out]
      end

      { data: opt_out_filtered_results, searchQuery: postcode }
    end
  end
end
