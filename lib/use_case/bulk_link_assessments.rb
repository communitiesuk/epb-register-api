module UseCase
  class BulkLinkAssessments
    def initialize(fetch_assessments_to_link_gateway:, address_base_gateway:, assessments_address_id_gateway:)
      @fetch_assessments_to_link_gateway = fetch_assessments_to_link_gateway
      @address_base_gateway = address_base_gateway
      @assessments_address_id_gateway = assessments_address_id_gateway
    end

    def execute
      @fetch_assessments_to_link_gateway.drop_table
      @fetch_assessments_to_link_gateway.create_and_populate_temp_table
      max_group_id = @fetch_assessments_to_link_gateway.get_max_group_id
      return if max_group_id.nil?

      (1..max_group_id).each do |group_id|
        domain_object = @fetch_assessments_to_link_gateway.fetch_assessments_by_group_id(group_id)
        domain_object.set_best_address_id(address_base_gateway: @address_base_gateway)
        @assessments_address_id_gateway.update_assessments_address_id_mapping(domain_object.get_assessment_ids, domain_object.best_address_id, "epb_bulk_linking")
      end
    end
  end
end
