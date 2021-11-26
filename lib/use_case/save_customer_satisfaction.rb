module UseCase
  class SaveCustomerSatisfaction
    def initialize(gateway)
      @gateway = gateway
    end

    def execute(satisfaction_object)
      if satisfaction_object.is_a?(OpenStruct)
        begin
          object = Domain::CustomerSatisfaction.new(Date.parse(satisfaction_object.stats_date),
                                                    satisfaction_object.very_satisfied,
                                                    satisfaction_object.satisfied,
                                                    satisfaction_object.neither,
                                                    satisfaction_object.dissatisfied,
                                                    satisfaction_object.very_dissatisfied)
          @gateway.upsert(object)
        rescue Date::Error
          raise Boundary::InvalidDate
        end
      else
        raise Boundary::ArgumentMissing unless satisfaction_object.is_a?(Domain::CustomerSatisfaction)

        @gateway.upsert(satisfaction_object)
      end
    end
  end
end
