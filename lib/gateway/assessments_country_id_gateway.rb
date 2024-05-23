module Gateway
  class AssessmentsCountryIdGateway
    class AssessmentsCountryId < ActiveRecord::Base
    end

    def insert(assessment_id:, country_id:)
      AssessmentsCountryId.create(assessment_id:, country_id:)
    end
  end
end
