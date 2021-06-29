ALL_SCOPES = %w[scheme:assessor:list scheme:list].freeze

def check_response(response, accepted_responses)
  if accepted_responses.include?(response.status)
    response
  else
    raise UnexpectedApiError.new(
      {
        expected_status: accepted_responses,
        actual_status: response.status,
        response_body: response.body,
      },
    )
  end
end

def assertive_request(
  request,
  accepted_responses,
  authenticate,
  auth_data,
  scopes = []
)
  response =
    if authenticate
      if auth_data
        authenticate_with_data(auth_data, scopes) { request.call }
      else
        authenticate_with_data({}, scopes) { request.call }
      end
    else
      request.call
    end
  check_response(response, accepted_responses)
end

def assertive_put(
  path,
  body,
  accepted_responses,
  authenticate,
  auth_data,
  scopes
)
  assertive_request(
    -> { put(path, body.to_json) },
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def assertive_delete(path, accepted_responses, authenticate, auth_data, scopes)
  assertive_request(
    -> { delete(path) },
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def assertive_get(path, accepted_responses, authenticate, auth_data, scopes)
  assertive_request(
    -> { get(path) },
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def assertive_post(
  path,
  body,
  accepted_responses,
  authenticate,
  auth_data,
  scopes,
  json = true
)
  body = body.to_json if json
  assertive_request(
    -> { post(path, body) },
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def fetch_assessors(
  scheme_id,
  accepted_responses = [200],
  authenticate = true,
  auth_data = nil,
  scopes = %w[scheme:assessor:list]
)
  assertive_get(
    "/api/schemes/#{scheme_id}/assessors",
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def fetch_assessor(
  scheme_id,
  assessor_id,
  accepted_responses = [200],
  authenticate = true,
  auth_data = nil,
  scopes = %w[scheme:assessor:fetch]
)
  auth_data ||= { 'scheme_ids': [scheme_id] }
  assertive_get(
    "/api/schemes/#{scheme_id}/assessors/#{assessor_id}",
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def fetch_assessor_current_status(
  first_name,
  last_name,
  date_of_birth,
  scheme_id,
  accepted_responses = [200],
  authenticate = true,
  auth_data = nil,
  scopes = %w[scheme:assessor:fetch]
)
  auth_data ||= { 'scheme_ids': [scheme_id] }
  date_of_birth_param = date_of_birth ? "&dateOfBirth=#{date_of_birth}" : ""
  assertive_get(
    "/api/assessors?firstName=#{first_name}&lastName=#{last_name}" +
      date_of_birth_param,
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def fetch_assessors_status(
  scheme_id,
  date,
  accepted_responses = [200],
  authenticate = true,
  auth_data = nil,
  scopes = %w[report:assessor:status]
)
  auth_data ||= { 'scheme_ids': [scheme_id] }
  assertive_get(
    "/api/reports/assessors/status?date=" + date,
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def fetch_assessors_updated_status(
  scheme_id,
  date,
  accepted_responses = [200],
  authenticate = true,
  auth_data = nil,
  scopes = %w[report:assessor:status]
)
  auth_data ||= { 'scheme_ids': [scheme_id] }
  assertive_get(
    "/api/reports/#{scheme_id}/assessors/status?date=" + date,
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def add_assessor(
  scheme_id,
  assessor_id,
  body,
  accepted_responses = [200, 201],
  authenticate = true,
  auth_data = nil,
  scopes = %w[scheme:assessor:update]
)
  auth_data ||= { 'scheme_ids': [scheme_id] }
  assertive_put(
    "/api/schemes/#{scheme_id}/assessors/#{assessor_id}",
    body,
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def add_scheme(
  name = "test scheme",
  accepted_responses = [201],
  authenticate = true,
  auth_data = nil,
  scopes = %w[scheme:create]
)
  assertive_post(
    "/api/schemes",
    { name: name, active: true },
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def update_scheme(
  scheme_id,
  scheme_body = {},
  accepted_responses = [204],
  authenticate = true,
  auth_data = nil,
  scopes = %w[scheme:update]
)
  assertive_put(
    "/api/schemes/#{scheme_id}",
    scheme_body,
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def add_green_deal_plan(
  assessment_id:,
  body: {},
  accepted_responses: [201],
  authenticate: true,
  auth_data: nil,
  scopes: %w[greendeal:plans]
)
  assertive_post(
    "/api/greendeal/disclosure/assessments/#{assessment_id}/plans",
    body,
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def update_green_deal_plan(
  plan_id:,
  body: {},
  accepted_responses: [200],
  authenticate: true,
  auth_data: nil,
  scopes: %w[greendeal:plans]
)
  assertive_put(
    "/api/greendeal/disclosure/plans/#{plan_id}",
    body,
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def delete_green_deal_plan(
  plan_id:,
  accepted_responses: [204],
  authenticate: true,
  auth_data: nil,
  scopes: %w[greendeal:plans]
)
  assertive_delete(
    "/api/greendeal/disclosure/plans/#{plan_id}",
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def fetch_green_deal_assessment_xml(
  assessment_id:,
  accepted_responses: [200],
  authenticate: true,
  auth_data: nil,
  scopes: %w[greendeal:plans]
)
  assertive_get(
    "/api/greendeal/assessments/#{assessment_id}/xml",
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def fetch_green_deal_assessment(
  assessment_id:,
  accepted_responses: [200],
  authenticate: true,
  auth_data: nil,
  scopes: %w[greendeal:plans]
)
  assertive_get(
    "/api/greendeal/assessments/#{assessment_id}",
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def lodge_assessment(
  assessment_body: "",
  accepted_responses: [201],
  authenticate: true,
  auth_data: nil,
  scopes: %w[assessment:lodge],
  json: false,
  schema_name: "RdSAP-Schema-20.0.0",
  headers: {},
  migrated: nil,
  override: nil,
  ensure_uprns: true
)
  # ensure "good" set of UPRNs (ones that are present in sample XML files) added to address_base table
  add_uprns_to_address_base("0", "1", "432167890000") if ensure_uprns

  path =
    if !migrated.nil?
      "api/assessments?migrated#{(migrated === true ? '' : '=' + migrated)}"
    elsif !override.nil?
      "api/assessments?override#{(override === true ? '' : '=' + override)}"
    else
      "api/assessments"
    end

  unless schema_name.nil?
    header "Content-type", "application/xml+" + schema_name
  end

  headers.each { |key, value| header key.to_s, value.to_s }

  assertive_post(
    path,
    assessment_body,
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
    json,
  )
end

def update_assessment_status(
  assessment_id: "",
  assessment_status_body: "",
  accepted_responses: [201],
  authenticate: true,
  auth_data: nil,
  scopes: %w[assessment:lodge]
)
  path = "api/assessments/" + assessment_id + "/status"
  header "Content-type", "application/json"

  assertive_post(
    path,
    assessment_status_body,
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
    true,
  )
end

def add_scheme_and_get_id(
  name = "test scheme",
  accepted_responses = [201],
  authenticate = true
)
  JSON.parse(add_scheme(name, accepted_responses, authenticate).body)["data"][
    "schemeId"
  ]
end

def add_scheme_then_assessor(body, accepted_responses = [200, 201])
  scheme_id = add_scheme_and_get_id
  add_assessor(scheme_id, "ACME123456", body, accepted_responses)
end

def add_super_assessor(scheme_id)
  add_assessor(
    scheme_id,
    "SPEC000000",
    AssessorStub.new.fetch_request_body(
      nonDomesticNos3: "ACTIVE",
      nonDomesticNos4: "ACTIVE",
      nonDomesticNos5: "ACTIVE",
      nonDomesticDec: "ACTIVE",
      domesticRdSap: "ACTIVE",
      domesticSap: "ACTIVE",
      nonDomesticSp3: "ACTIVE",
      nonDomesticCc4: "ACTIVE",
      gda: "ACTIVE",
    ),
  )
end

def call_lodge_assessment(scheme_id:, schema_name:, xml_document:, migrated: nil, ensure_uprns: true)
  lodge_assessment(
    assessment_body: xml_document.to_xml,
    accepted_responses: [201],
    auth_data: {
      scheme_ids: [scheme_id],
    },
    scopes: %w[assessment:lodge migrate:assessment],
    override: true,
    schema_name: schema_name,
    migrated: migrated,
    ensure_uprns: ensure_uprns,
  )
end

def fetch_renewable_heat_incentive(
  assessment_id,
  accepted_responses = [200],
  authenticate = true,
  auth_data = nil,
  scopes = %w[greendeal:plans],
  headers: {}
)
  headers.each { |key, value| header key.to_s, value.to_s }

  assertive_get(
    "api/greendeal/rhi/assessments/#{assessment_id}/latest",
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def fetch_assessment(
  assessment_id,
  accepted_responses = [200],
  authenticate = true,
  auth_data = nil,
  scopes = %w[assessment:fetch],
  headers: {}
)
  headers.each { |key, value| header key.to_s, value.to_s }

  assertive_get(
    "api/assessments/#{assessment_id}",
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def fetch_assessment_summary(
  assessment_id,
  accepted_responses = [200],
  authenticate = true,
  auth_data = nil,
  scopes = %w[assessment:fetch],
  headers: {}
)
  assertive_get(
    "api/assessments/#{assessment_id}/summary",
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def fetch_dec_summary(
  assessment_id,
  accepted_responses = [200],
  authenticate = true,
  auth_data = nil,
  scopes = %w[dec_summary:fetch],
  headers: {}
)
  assertive_get(
    "api/dec_summary/#{assessment_id}",
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def assessments_search_by_postcode(
  postcode,
  accepted_responses = [200],
  authenticate = true,
  auth_data = nil,
  scopes = %w[assessment:search],
  assessment_types = %w[RdSAP SAP]
)
  path = "/api/assessments/search?postcode=#{postcode}"

  assessment_types.each do |assessment_type|
    path <<
      (path.include?("?") ? "&" : "?") + "assessment_type[]=" + assessment_type
  end

  assertive_get(path, accepted_responses, authenticate, auth_data, scopes)
end

def domestic_assessments_search_by_assessment_id(
  assessment_id,
  accepted_responses = [200],
  authenticate = true,
  auth_data = nil,
  scopes = %w[assessment:search]
)
  assertive_get(
    "/api/assessments/search?assessment_id=#{assessment_id}",
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def assessments_search_by_street_name_and_town(
  street_name,
  town,
  accepted_responses = [200],
  assessment_types = %w[RdSAP SAP],
  authenticate = true,
  auth_data = nil,
  scopes = %w[assessment:search]
)
  path = "/api/assessments/search?street_name=#{street_name}&town=#{town}"
  assessment_types.each do |assessment_type|
    path <<
      (path.include?("?") ? "&" : "?") + "assessment_type[]=" + assessment_type
  end

  assertive_get(path, accepted_responses, authenticate, auth_data, scopes)
end

def assessors_search(
  postcode,
  qualification,
  accepted_responses = [200],
  authenticate = true,
  auth_data = nil,
  scopes = %w[assessor:search]
)
  assertive_get(
    "/api/assessors?postcode=#{postcode}&qualification=#{qualification}",
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def assessors_search_by_name(
  name,
  accepted_responses = [200],
  authenticate = true,
  auth_data = nil,
  scopes = %w[assessor:search]
)
  assertive_get(
    "/api/assessors?name=#{name}",
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def schemes_list(
  accepted_responses = [200],
  authenticate = true,
  auth_data = nil,
  scopes = %w[scheme:list]
)
  assertive_get(
    "/api/schemes",
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def address_search_by_id(
  address_id,
  accepted_responses = [200],
  authenticate = true,
  auth_data = {},
  scopes = %w[address:search]
)
  assertive_get(
    "/api/search/addresses?addressId=#{address_id}",
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def address_search_by_postcode(
  postcode,
  accepted_responses = [200],
  authenticate = true,
  auth_data = {},
  scopes = %w[address:search]
)
  assertive_get(
    "/api/search/addresses?postcode=#{postcode}",
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def get_assessment_report(
  start_date:,
  end_date:,
  scheme_id: nil,
  type: "region-and-type",
  accepted_responses: [200],
  authenticate: true,
  auth_data: {},
  scopes: %w[reporting:assessment_by_type_and_region]
)
  if type.include? "scheme-and-type"
    scopes = %w[reporting:assessment_by_scheme_and_type]
  end

  url =
    "/api/reports/assessments/#{type}?startDate=#{start_date}&endDate=#{
      end_date
    }"

  url << "&scheme_id=#{scheme_id}" unless scheme_id.nil?

  assertive_get(url, accepted_responses, authenticate, auth_data, scopes)
end

def opt_out_assessment(
  assessment_id,
  accepted_responses = [200],
  authenticate = true,
  auth_data = {},
  scopes = %w[admin:opt_out]
)
  assertive_put(
    "/api/assessments/#{assessment_id}/opt-out",
    "",
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end

def update_assessment_address_id(
  assessment_id,
  new_address_id,
  accepted_responses = [200],
  authenticate = true,
  auth_data = {},
  scopes = %w[admin:update-address-id]
)
  assertive_put(
    "/api/assessments/#{assessment_id}/address-id",
    { "addressId": new_address_id },
    accepted_responses,
    authenticate,
    auth_data,
    scopes,
  )
end
