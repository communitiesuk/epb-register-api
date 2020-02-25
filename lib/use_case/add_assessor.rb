module UseCase
  class AddAssessor
    class SchemeNotFoundException < Exception; end

    class InvalidAssessorDetailsException < Exception; end

    class AssessorRegisteredOnAnotherScheme < Exception; end

    def initialize(schemes_gateway, assessors_gateway)
      @schemes_gateway = schemes_gateway
      @assessors_gateway = assessors_gateway
    end

    def execute(scheme_id, scheme_assessor_id, assessor)
      scheme =
        @schemes_gateway.all.select do |scheme|
          scheme[:scheme_id].to_s == scheme_id.to_s
        end.first
      existing_assessor = @assessors_gateway.fetch_as_model(scheme_assessor_id)

      raise SchemeNotFoundException unless scheme

      if existing_assessor &&
           existing_assessor.registered_by_id.to_s != scheme_id.to_s
        raise AssessorRegisteredOnAnotherScheme
      end

      new_assessor = {
        first_name: assessor[:first_name],
        last_name: assessor[:last_name],
        date_of_birth: assessor[:date_of_birth],
        search_results_comparison_postcode:
          assessor[:search_results_comparison_postcode]
      }

      if assessor.key?(:middle_names)
        new_assessor[:middle_names] = assessor[:middle_names]
      end

      if assessor.key?(:contact_details)
        new_assessor[:contact_details] = {}
        if assessor[:contact_details].key?(:telephone_number)
          new_assessor[:contact_details][:telephone_number] =
            assessor[:contact_details][:telephone_number]
        end

        if assessor[:contact_details].key?(:email)
          new_assessor[:contact_details][:email] =
            assessor[:contact_details][:email]
        end
      end

      if assessor.key?(:qualifications)
        new_assessor[:qualifications] = assessor[:qualifications]
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
      {
        assessor_was_newly_created: (existing_assessor == nil),
        assessor: created_assessor
      }
    end
  end
end
