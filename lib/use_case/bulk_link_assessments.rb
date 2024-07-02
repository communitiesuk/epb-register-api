module UseCase
  class BulkLinkAssessments
    def initialize(fetch_assessments_to_link_gateway:, address_base_gateway:, assessments_address_id_gateway:)
      @fetch_assessments_to_link_gateway = fetch_assessments_to_link_gateway
      @address_base_gateway = address_base_gateway
      @assessments_address_id_gateway = assessments_address_id_gateway
    end

    def execute
      @fetch_assessments_to_link_gateway.drop_temp_table
      @fetch_assessments_to_link_gateway.create_and_populate_temp_table
      max_group_id = @fetch_assessments_to_link_gateway.get_max_group_id
      return if max_group_id.nil?

      skip_group_ids = @fetch_assessments_to_link_gateway.fetch_duplicate_address_ids
      groups_ids = [*1..max_group_id] - skip_group_ids

      groups_ids.each do |group_id|
        begin
          domain_object = @fetch_assessments_to_link_gateway.fetch_assessments_by_group_id(group_id)
        rescue Boundary::NoData => e
          report_to_sentry(e)
          next
        end

        domain_object.set_best_address_id(address_base_gateway: @address_base_gateway)
        @assessments_address_id_gateway.update_assessments_address_id_mapping(domain_object.get_assessment_ids, domain_object.best_address_id, "epb_bulk_linking")
      end
    end
  end
end
