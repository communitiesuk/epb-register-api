module Events
  class Listener
    def initialize(event_broadcaster)
      @event_broadcaster = event_broadcaster
    end

    def attach_listeners
      attach_assessment_lodged
      attach_assessment_cancellation
      attach_assessment_address
      attach_assessment_status
      attach_green_deal_plan_added
      attach_green_deal_plan_updated
      attach_green_deal_plan_deleted
      attach_assessor_added
      attach_match_address_request
    end

  private

    def attach_assessment_lodged
      @event_broadcaster.on :assessment_lodged do |**data|
        NotifyFactory.lodgement_to_audit_log(entity_id: data[:assessment_id])
        if notify_data_warehouse_enabled?
          NotifyFactory.new_assessment_to_data_warehouse_use_case.execute(assessment_id: data[:assessment_id], is_scottish: data[:is_scottish])
        end
        # feature flag here with call to addressing app - send just the matched address id -
        # when we have an address then send it to this will broadcast and will send a new queue  rrn:matched_address_id
        # if there is a failure what to do that raise error ? alerted by error
        # If issue - can run backfill (which will ideally use the use case) - this can then broadcast and send to queue - will this have access to listeners etc
        # Notify warehouse from the match address use case - so backfilling will also fill - new queue - Warehouse can deal with retries.
        # NotifyFactory.lodgement_to_audit_log(entity_id: data[:assessment_id])
      end
    end

    def attach_match_address_request
      @event_broadcaster.on :match_address_request do |**data|
        # if Helper::Toggles.enabled?("address-matching-during-lodgement")
        if address_matching_during_lodgement_enabled?
          match_address_use_case = ApiFactory.match_assessment_address_use_case
          match_address_use_case.execute(
            assessment_id: data.fetch(:assessment_id),
            address_line_1: data.fetch(:address_line1),
            address_line_2: data.fetch(:address_line2),
            address_line_3: data.fetch(:address_line3),
            address_line_4: data.fetch(:address_line4),
            town: data.fetch(:town),
            postcode: data.fetch(:postcode),
          )
        end
      rescue KeyError
        raise Errors::MissingRequiredParameterError
      end
    end

    def attach_assessment_cancellation
      @event_broadcaster.on :assessment_cancelled, :assessment_marked_not_for_issue do |**data|
        if notify_data_warehouse_enabled?
          NotifyFactory.assessment_status_update_to_data_warehouse_use_case.execute(assessment_id: data[:assessment_id])
        end
        NotifyFactory.cancelled_to_audit_log(entity_id: data[:assessment_id])
      end
    end

    def attach_assessment_address
      @event_broadcaster.on :assessment_address_id_updated do |**data|
        if notify_data_warehouse_enabled?
          NotifyFactory.assessment_address_id_update_to_data_warehouse_use_case.execute(assessment_id: data[:assessment_id], address_id: data[:new_address_id])
        end
        NotifyFactory.address_id_updated_to_audit_log(entity_id: data[:assessment_id])
      end
    end

    def attach_assessment_status
      @event_broadcaster.on :assessment_opt_out_status_changed do |**data|
        if notify_data_warehouse_enabled?
          NotifyFactory.opt_out_status_update_to_data_warehouse_use_case.execute(assessment_id: data[:assessment_id])
        end
        NotifyFactory.opt_out_to_audit_log(entity_id: data[:assessment_id], is_opt_out: data[:new_status])
      end
    end

    def attach_green_deal_plan_added
      @event_broadcaster.on :green_deal_plan_added do |**data|
        NotifyFactory.green_deal_plan_added_to_audit_log(entity_id: data[:green_deal_plan_id], assessment_id: data[:assessment_id])
      end
    end

    def attach_green_deal_plan_updated
      @event_broadcaster.on :green_deal_plan_updated do |**data|
        NotifyFactory.green_deal_plan_updated_to_audit_log(entity_id: data[:green_deal_plan_id], assessment_ids: data[:assessment_ids])
      end
    end

    def attach_green_deal_plan_deleted
      @event_broadcaster.on :green_deal_plan_deleted do |**data|
        NotifyFactory.green_deal_plan_deleted_to_audit_log(entity_id: data[:green_deal_plan_id], assessment_ids: data[:assessment_ids])
      end
    end

    def attach_assessor_added
      @event_broadcaster.on :assessor_added do |**data|
        NotifyFactory.assessor_added_to_audit_log(entity_id: data[:assessor_id])
      end
    end

    def notify_data_warehouse_enabled?
      ENV["STAGE"] != "test"
    end

    def address_matching_during_lodgement_enabled?
      Helper::Toggles.enabled?("address-matching-during-lodgement")
    end
  end
end
