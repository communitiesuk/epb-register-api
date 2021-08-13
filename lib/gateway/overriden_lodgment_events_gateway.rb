module Gateway
  class OverridenLodgmentEventsGateway
    class OveriddenLodgementEvent < ActiveRecord::Base
    end

    def add(assessment_id, validation_result)
      overidden_event =
        OveriddenLodgementEvent.create(
          assessment_id: assessment_id,
          rule_triggers: validation_result,
        )

      overidden_event.save
    end
  end
end
