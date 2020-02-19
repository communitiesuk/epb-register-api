class AssessorGatewayFake
  attr_reader :saved_assessor_details,
              :saved_registered_by,
              :saved_scheme_assessor_id

  def initialize(result)
    @result = result
    @saved_scheme_assessor_id = false
    @saved_assessor_details = false
    @saved_registered_by = false
    @saved_latitude = false
    @saved_longitude = false
    @saved_name = false
  end

  def fetch(*)
    @result
  end

  def update(scheme_assessor_id, registered_by, assessor_details)
    @saved_scheme_assessor_id = scheme_assessor_id
    @saved_assessor_details = assessor_details
    @saved_registered_by = registered_by
  end

  def search(latitude, longitude)
    @saved_latitude = latitude
    @saved_longitude = longitude

    @result
  end

  def search_by(name)
    @saved_name = name

    @result
  end
end
