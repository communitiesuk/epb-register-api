module UseCase
  class AddAssessor

    class SchemeNotFoundException < Exception
    end

    class InvalidAssessorDetailsException < Exception
    end

    def initialize(gateway)
      @gateway = gateway
    end

    def validate_input(assessor)
      errors = []
      unless (Date.strptime(assessor[:date_of_birth], '%Y-%m-%d') rescue false)
        errors << "INVALID_DATE_OF_BIRTH"
      end

      unless assessor[:first_name].class == String
        errors << "INVALID_FIRST_NAME"
      end

      errors
    end

    def execute(scheme_id, scheme_assessor_id, assessor)
      scheme = @gateway.all.select { |scheme| scheme[:scheme_id].to_s == scheme_id }[0]
      errors = validate_input(assessor)

      unless errors.empty?
        raise InvalidAssessorDetailsException
      end

      if scheme
        created_assessor = {
          registered_by: {
              scheme_id: scheme_id,
              name: scheme[:name]
          },
          scheme_assessor_id: scheme_assessor_id,
          first_name: assessor[:first_name],
          last_name: assessor[:last_name],
          date_of_birth: assessor[:date_of_birth]
        }

        if assessor.key?(:middle_names)
          created_assessor[:middle_names] = assessor[:middle_names]
        end

        created_assessor
      else
        raise SchemeNotFoundException
      end
    end
  end
end
