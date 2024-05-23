module Gateway
  class AssessmentsCountryIdGateway
    class AssessmentsCountryId < ActiveRecord::Base
    end

    def insert(assessment_id:, country_id:)
      ActiveRecord::Base.transaction do
       AssessmentsCountryId.create(assessment_id:, country_id:)
      end
    rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionFailed
      # ...which we ignore.
    end

  end
end



