describe NotifyFactory do
  let(:save_audit_event_use_case) { instance_spy(UseCase::SaveAuditEvent) }

  describe "notify to audit log" do
    notifiers = described_class.methods.select { |method| method.ends_with?("to_audit_log") }

    notifiers.each do |notifier_method|
      it "#{notifier_method} calls the save audit event use case" do
        args = notifier_method == :opt_out_to_audit_log ? { entity_id: "0000-0000", is_opt_out: true } : { entity_id: "0000-0000" }

        expect { described_class.send(notifier_method, args) }.not_to raise_error
      end
    end
  end
end
