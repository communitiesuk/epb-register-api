module EventsManager

  def self.attach_listeners
    return @event_broadcaster unless @event_broadcaster.nil?

    @event_broadcaster = EventBroadcaster.new(logger: ApiFactory.logger)

    # wire up listeners
    #
    # don't send out to data warehouse queue yet
    #
    @event_broadcaster.on :assessment_lodged do |**data|
      if notify_data_warehouse_enabled?
        NotifyFactory.new_assessment_to_data_warehouse_use_case.execute(
          assessment_id: data[:assessment_id],
          )
      end
      NotifyFactory.lodgement_to_audit_log(entity_id: data[:assessment_id])
    end

    @event_broadcaster.on :assessment_cancelled, :assessment_marked_not_for_issue do |**data|
      if notify_data_warehouse_enabled?
        NotifyFactory.assessment_status_update_to_data_warehouse_use_case.execute(
          assessment_id: data[:assessment_id],
          )
      end
      NotifyFactory.cancelled_to_audit_log(entity_id: data[:assessment_id])
    end

    @event_broadcaster.on :assessment_address_id_updated do |**data|
      if notify_data_warehouse_enabled?
        NotifyFactory.assessment_address_id_update_to_data_warehouse_use_case.execute(
          assessment_id: data[:assessment_id],
          )
      end
      NotifyFactory.address_id_updated_to_audit_log(entity_id: data[:assessment_id])
    end

    @event_broadcaster.on :assessment_opt_out_status_changed do |**data|
      if notify_data_warehouse_enabled?
        NotifyFactory.opt_out_status_update_to_data_warehouse_use_case.execute(
          assessment_id: data[:assessment_id],
          )
      end
      NotifyFactory.opt_out_to_audit_log(entity_id: data[:assessment_id], is_opt_out: data[:new_status])
    end

    @event_broadcaster.on :green_deal_plan_added do |**data|
      NotifyFactory.green_deal_plan_added_to_audit_log(entity_id: data[:assessment_id])
    end

    @event_broadcaster.on :green_deal_plan_updated do |**data|
      NotifyFactory.green_deal_plan_updated_to_audit_log(entity_id: data[:assessment_id])
    end

    @event_broadcaster.on :green_deal_plan_deleted do |**data|
      NotifyFactory.green_deal_plan_deleted_to_audit_log(entity_id: data[:assessment_id])
    end

    @event_broadcaster.on :assessor_added do |**data|
      NotifyFactory.assessor_added_to_audit_log(entity_id: data[:assessor_id])
    end

    @event_broadcaster
  end

  def self.notify_data_warehouse_enabled?
    Helper::Toggles.enabled? "sync_to_data_warehouse"
  end

  private_class_method :notify_data_warehouse_enabled?

end
