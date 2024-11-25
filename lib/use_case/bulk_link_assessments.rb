module UseCase
  class BulkLinkAssessments
    def initialize(fetch_assessments_to_link_gateway:, address_base_gateway:, assessments_address_id_gateway:, event_broadcaster:)
      @fetch_assessments_to_link_gateway = fetch_assessments_to_link_gateway
      @address_base_gateway = address_base_gateway
      @assessments_address_id_gateway = assessments_address_id_gateway
      @event_broadcaster = event_broadcaster
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
          if @fetch_assessments_to_link_gateway.contains_manually_set_address_ids(group_id)
            next
          end

          assessments_to_link = @fetch_assessments_to_link_gateway.fetch_assessments_by_group_id(group_id)
        rescue Boundary::NoData => e
          report_to_sentry(e)
          next
        end

        assessments_to_link.set_best_address_id(address_base_gateway: @address_base_gateway)
        @assessments_address_id_gateway.update_assessments_address_id_mapping(assessments_to_link.get_assessment_ids, assessments_to_link.best_address_id, "epb_bulk_linking")

        assessments_to_link.get_assessment_ids.each do |id|
          @event_broadcaster.broadcast :assessment_address_id_updated,
                                       assessment_id: id,
                                       new_address_id: assessments_to_link.best_address_id
        end
      end
    end
  end
end
