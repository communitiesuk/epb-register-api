module UseCase
  class AddAssessor

    class SchemeNotFoundException < Exception

    end

    def initialize(gateway)
      @gateway = gateway
    end

    def execute(scheme_id, scheme_assessor_id, assessor)
      scheme = @gateway.all.select { |scheme| scheme[:scheme_id].to_s == scheme_id}[0]

      if scheme
        {
            registeredBy: {
                schemeId: scheme_id,
                name: scheme[:name]
            },
            schemeAssessorId: scheme_assessor_id,
            firstName: assessor['firstName'],
            middleNames: assessor['middleNames'],
            lastName: assessor['lastName'],
            dateOfBirth: assessor['dateOfBirth']
        }
      else
        raise SchemeNotFoundException
      end
    end
  end
end
