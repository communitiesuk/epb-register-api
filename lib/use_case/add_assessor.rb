module UseCase
  class AddAssessor

    class SchemeNotFoundException < Exception
    end

    class InvalidAssessorDetailsException < Exception
    end

    def initialize(gateway)
      @gateway = gateway
    end

    def valid_date?( str)
      Date.strptime(str,"%m/%d/%Y") rescue false
    end


    def execute(scheme_id, scheme_assessor_id, assessor)
      scheme = @gateway.all.select { |scheme| scheme[:scheme_id].to_s == scheme_id}[0]

      if valid_date?(assessor[:date_of_birth])
        raise InvalidAssessorDetailsException
      end

      if scheme
        {
            registeredBy: {
                schemeId: scheme_id,
                name: scheme[:name]
            },
            schemeAssessorId: scheme_assessor_id,
            firstName: assessor[:first_name],
            middleNames: assessor[:middle_names],
            lastName: assessor[:last_name],
            dateOfBirth: assessor[:date_of_birth]
        }
      else
        raise SchemeNotFoundException
      end
    end
  end
end
