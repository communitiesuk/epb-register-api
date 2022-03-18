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
      attach_green_deal_plan_updated
      attach_green_deal_plan_deleted
      attach_assessor_added
    end

  private

    def attach_assessment_lodged
      @event_broadcaster.on :assessment_lodged do |**data|
        if notify_data_warehouse_enabled?
          NotifyFactory.new_assessment_to_data_warehouse_use_case.execute(assessment_id: data[:assessment_id])
        end
        NotifyFactory.lodgement_to_audit_log(entity_id: data[:assessment_id])
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
          NotifyFactory.assessment_address_id_update_to_data_warehouse_use_case.execute(assessment_id: data[:assessment_id])
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
      Helper::Toggles.enabled? "sync_to_data_warehouse"
    end
  end
end
