module Gateway
  class AssessorsGateway
    class Assessor < ActiveRecord::Base; end

    def fetch(scheme_assessor_id)
      Assessor.find_by(scheme_assessor_id: scheme_assessor_id)
    end

    def update(scheme_assessor_id, registered_by, assessor_details)
      assessor = assessor_details.dup
      assessor[:registered_by] = registered_by
      assessor[:scheme_assessor_id] = scheme_assessor_id

      existing_assessor =
        Assessor.find_by(
          scheme_assessor_id: scheme_assessor_id, registered_by: registered_by
        )
      if existing_assessor
        existing_assessor.update(assessor)
      else
        Assessor.create(assessor)
      end
    end
  end
end
