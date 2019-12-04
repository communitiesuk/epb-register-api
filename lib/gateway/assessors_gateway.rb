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

      Assessor.create(assessor)
    end
  end
end
