module UseCase
  class FetchScottishAssessors
    # frozen_string_literal: true

    def initialize(gateway)
      @gateway = gateway
    end

    def execute(start_date:, end_date:, current_page:, records_per_page: 5000)
      {
        new_assessors: @gateway.search_by_date(start_date:, end_date:, current_page:, limit: records_per_page),
      }
    end
  end
end
