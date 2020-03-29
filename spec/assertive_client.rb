def assertive_put(path, body, accepted_responses)
  response = authenticate_and { put(path, body.to_json) }
  check_response(response, accepted_responses)
end

def assertive_get(path, accepted_responses)
  response = authenticate_and { get(path) }
  check_response(response, accepted_responses)
end

def assertive_post(path, body, accepted_responses)
  response = authenticate_and { post(path, body.to_json) }
  check_response(response, accepted_responses)
end

def fetch_assessors(scheme_id, accepted_responses = [200])
  get("/api/schemes/#{scheme_id}/assessors")
end

def fetch_assessor(scheme_id, assessor_id)
  authenticate_and { get("/api/schemes/#{scheme_id}/assessors/#{assessor_id}") }
end

def add_assessor(scheme_id, assessor_id, body, accepted_responses = [200, 201])
  assertive_put(
      "/api/schemes/#{scheme_id}/assessors/#{assessor_id}",
      body,
      accepted_responses
  )
end

def add_scheme(name = 'test scheme', accepted_responses = [201])
  JSON.parse(
      assertive_post('/api/schemes', { name: name }, accepted_responses).body
  )[
      'data'
  ][
      'schemeId'
  ]
end

def add_scheme_then_assessor(body, accepted_responses = [200, 201])
  scheme_id = add_scheme
  response = add_assessor(scheme_id, 'TEST_ASSESSOR', body, accepted_responses)
  response
end

def fetch_assessment(assessment_id, accepted_responses = [200])
  assertive_get(
      "api/assessments/domestic-epc/#{assessment_id}",
      accepted_responses
  )
end

def migrate_assessment(
    assessment_id, assessment_body, accepted_responses = [200]
)
  assertive_put(
      "api/assessments/domestic-epc/#{assessment_id}",
      assessment_body,
      accepted_responses
  )
end

def assessments_search_by_postcode(postcode, accepted_responses = [200])
  assertive_get(
      "/api/assessments/domestic-epc/search?postcode=#{postcode}",
      accepted_responses
  )
end

def assessments_search_by_assessment_id(
    assessment_id, accepted_responses = [200]
)
  assertive_get(
      "/api/assessments/domestic-epc/search?assessment_id=#{assessment_id}",
      accepted_responses
  )
end

def assessments_search_by_street_name_and_town(
    street_name, town, accepted_responses = [200]
)
  assertive_get(
      "/api/assessments/domestic-epc/search?street_name=#{street_name}&town=#{
      town
      }",
      accepted_responses
  )
end
