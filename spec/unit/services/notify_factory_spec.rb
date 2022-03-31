describe NotifyFactory do
  let(:save_audit_event_use_case) { instance_spy(UseCase::SaveAuditEvent) }

  describe "notify to audit log" do
    notifiers = described_class.methods.select { |method| method.end_with?("to_audit_log") }

    notifiers.each do |notifier_method|
      it "#{notifier_method} calls the save audit event use case" do
        args = case notifier_method
               when :opt_out_to_audit_log
                 { entity_id: "0000-0000", is_opt_out: true }
               when :green_deal_plan_added_to_audit_log
                 { entity_id: "AB234234535", assessment_id: %w[0000-0000] }
               when :green_deal_plan_updated_to_audit_log, :green_deal_plan_deleted_to_audit_log
                 { entity_id: "AB234234535", assessment_ids: %w[0000-0000] }
               else
                 { entity_id: "0000-0000" }
               end

        expect { described_class.send(notifier_method, args) }.not_to raise_error
      end
    end
  end
end
