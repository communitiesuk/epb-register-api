module Gateway
  class OverriddenLodgmentEventsGateway
    class OverriddenLodgementEvent < ActiveRecord::Base
    end

    def add(assessment_id, validation_result)
      overridden_event =
        OverriddenLodgementEvent.create(
          assessment_id:,
          rule_triggers: validation_result,
        )

      overridden_event.save
    end
  end
end
