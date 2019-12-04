module UseCase
  class AddAssessor
    class SchemeNotFoundException < Exception; end

    class InvalidAssessorDetailsException < Exception; end

    class AssessorRegisteredOnAnotherScheme < Exception; end

    def initialize(schemes_gateway, assessors_gateway)
      @schemes_gateway = schemes_gateway
      @assessors_gateway = assessors_gateway
    end

    def validate_input(assessor)
      errors = []
      unless (
               begin
                 Date.strptime(assessor[:date_of_birth], '%Y-%m-%d')
               rescue StandardError
                 false
               end
             )
        errors << 'INVALID_DATE_OF_BIRTH'
      end

      unless assessor[:first_name].class == String
        errors << 'INVALID_FIRST_NAME'
      end

      errors << 'INVALID_LAST_NAME' unless assessor[:last_name].class == String

      if assessor[:middle_names] && assessor[:middle_names].class != String
        errors << 'INVALID_MIDDLE_NAMES'
      end

      errors
    end

    def execute(scheme_id, scheme_assessor_id, assessor)
      scheme =
        @schemes_gateway.all.select do |scheme|
          scheme[:scheme_id].to_s == scheme_id.to_s
        end[
          0
        ]
      existing_assessor = @assessors_gateway.fetch(scheme_assessor_id)
      errors = validate_input(assessor)

      raise SchemeNotFoundException unless scheme

      if existing_assessor &&
           existing_assessor[:registered_by].to_s != scheme_id.to_s
        raise AssessorRegisteredOnAnotherScheme
      end

      raise InvalidAssessorDetailsException unless errors.empty?

      if scheme
        new_assessor = {
          first_name: assessor[:first_name],
          last_name: assessor[:last_name],
          date_of_birth: assessor[:date_of_birth]
        }

        if assessor.key?(:middle_names)
          new_assessor[:middle_names] = assessor[:middle_names]
        end

        @assessors_gateway.update(
          scheme_assessor_id,
          scheme[:scheme_id],
          new_assessor
        )

        created_assessor = new_assessor.dup
        created_assessor[:registered_by] = {
          scheme_id: scheme_id, name: scheme[:name]
        }
        created_assessor[:scheme_assessor_id] = scheme_assessor_id
        created_assessor
      end
    end
  end
end
