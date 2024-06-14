module UseCase
  class BulkLinkAssessments
    def initialize(fetch_assessments_to_link_gateway:)
      @fetch_assessments_to_link_gateway = fetch_assessments_to_link_gateway
    end

    def execute
      @fetch_assessments_to_link_gateway.create_and_populate_temp_table
      max_group_id = @fetch_assessments_to_link_gateway.get_max_group_id
      (1..max_group_id).each do |group_id|
        @fetch_assessments_to_link_gateway.fetch_by_group_id(group_id)
      end
    end
  end
end
