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
  accepted_responses:,
  should_authenticate:,
  auth_data:,
  scopes: [], &block
)
  response =
    if should_authenticate
      if auth_data
        authenticate_with_data(scopes:, data: auth_data, &block)
      else
        authenticate_with_data(scopes:, &block)
      end
    else
      yield
    end
  check_response(response, accepted_responses)
end

def assertive_put(
  path,
  body:,
  accepted_responses:,
  auth_data: {},
  scopes: [],
  should_authenticate: true
)

  assertive_request(
    accepted_responses:,
    should_authenticate:,
    auth_data:,
    scopes:,
  ) { put(path, body.to_json) }
end

def assertive_delete(path, accepted_responses:, should_authenticate:, auth_data:, scopes:)
  assertive_request(
    accepted_responses:,
    should_authenticate:,
    auth_data:,
    scopes:,
  ) { delete(path) }
end

def assertive_get(path, scopes: [], accepted_responses: [200], should_authenticate: true, auth_data: {})
  assertive_request(
    accepted_responses:,
    should_authenticate:,
    auth_data:,
    scopes:,
  ) { get(path) }
end

def assertive_post(
  path,
  body:,
  should_authenticate: true,
  scopes: [],
  auth_data: {},
  accepted_responses: [201],
  json: true
)
  body = body.to_json if json
  assertive_request(
    accepted_responses:,
    should_authenticate:,
    auth_data:,
    scopes:,
  ) { post(path, body) }
end

def fetch_assessors(
  scheme_id:,
  scopes: %w[scheme:assessor:list],
  **assertive_client_kwargs
)
  assertive_get(
    "/api/schemes/#{scheme_id}/assessors",
    scopes:,
    **assertive_client_kwargs,
  )
end

def fetch_assessor(
  scheme_id:,
  assessor_id:,
  auth_data: nil,
  scopes: %w[scheme:assessor:fetch],
  **assertive_kwargs
)
  auth_data ||= { 'scheme_ids': [scheme_id] }
  assertive_get(
    "/api/schemes/#{scheme_id}/assessors/#{assessor_id}",
    auth_data:,
    scopes:,
    **assertive_kwargs,
  )
end

def fetch_assessor_current_status(
  first_name:,
  last_name:,
  scheme_id:,
  date_of_birth: nil,
  scopes: %w[scheme:assessor:fetch],
  auth_data: nil,
  **assertive_kwargs
)
  auth_data ||= { 'scheme_ids': [scheme_id] }
  date_of_birth_param = date_of_birth ? "&dateOfBirth=#{date_of_birth}" : ""
  assertive_get(
    "/api/assessors?firstName=#{first_name}&lastName=#{last_name}" +
      date_of_birth_param,
    scopes:,
    auth_data:,
    **assertive_kwargs,
  )
end

def fetch_assessors_updated_status(
  scheme_id:,
  date:,
  auth_data: nil,
  scopes: %w[report:assessor:status],
  **assertive_kwargs
)
  auth_data ||= { 'scheme_ids': [scheme_id] }
  assertive_get(
    "/api/reports/#{scheme_id}/assessors/status?date=" + date,
    auth_data:,
    scopes:,
    **assertive_kwargs,
  )
end

def add_assessor(
  scheme_id:,
  assessor_id:,
  body:,
  accepted_responses: [200, 201],
  auth_data: nil,
  scopes: %w[scheme:assessor:update],
  **assertive_kwargs
)
  auth_data ||= { 'scheme_ids': [scheme_id] }
  assertive_put(
    "/api/schemes/#{scheme_id}/assessors/#{assessor_id}",
    body:,
    accepted_responses:,
    auth_data:,
    scopes:,
    **assertive_kwargs,
  )
end

def add_scheme(
  name: "test scheme",
  accepted_responses: [201],
  scopes: %w[scheme:create],
  **assertive_kwargs
)
  assertive_post(
    "/api/schemes",
    body: { name:, active: true },
    accepted_responses:,
    scopes:,
    **assertive_kwargs,
  )
end

def update_scheme(
  scheme_id:,
  body: {},
  accepted_responses: [204],
  scopes: %w[scheme:update],
  **assertive_kwargs
)
  assertive_put(
    "/api/schemes/#{scheme_id}",
    body:,
    accepted_responses:,
    scopes:,
    **assertive_kwargs,
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
    body:,
    accepted_responses:,
    should_authenticate: authenticate,
    auth_data:,
    scopes:,
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
    body:,
    accepted_responses:,
    should_authenticate: authenticate,
    auth_data:,
    scopes:,
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
    accepted_responses:,
    should_authenticate: authenticate,
    auth_data:,
    scopes:,
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
    accepted_responses:,
    should_authenticate: authenticate,
    auth_data:,
    scopes:,
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
    accepted_responses:,
    should_authenticate: authenticate,
    auth_data:,
    scopes:,
  )
end

def lodge_assessment(
  assessment_body: "",
  accepted_responses: [201],
  authenticate: true,
  auth_data: nil,
  scopes: %w[assessment:lodge migrate:assessment],
  json: false,
  schema_name: "RdSAP-Schema-20.0.0",
  headers: {},
  migrated: nil,
  override: nil,
  ensure_uprns: true
)
  # ensure "good" range of UPRNs added to address_base table
  add_uprns_to_address_base("0", "1") if ensure_uprns

  path =
    if !migrated.nil?
      "api/assessments?migrated#{migrated == true ? '' : "=#{migrated}"}"
    elsif !override.nil?
      "api/assessments?override#{override == true ? '' : "=#{override}"}"
    else
      "api/assessments"
    end

  unless schema_name.nil?
    header "Content-type", "application/xml+#{schema_name}"
  end

  headers.each { |key, value| header key.to_s, value.to_s }

  assertive_post(
    path,
    body: assessment_body,
    accepted_responses:,
    should_authenticate: authenticate,
    auth_data:,
    scopes:,
    json:,
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
  path = "api/assessments/#{assessment_id}/status"
  header "Content-type", "application/json"

  assertive_post(
    path,
    body: assessment_status_body,
    accepted_responses:,
    should_authenticate: authenticate,
    auth_data:,
    scopes:,
    json: true,
  )
end

def add_scheme_and_get_id(
  name: "test scheme",
  accepted_responses: [201],
  should_authenticate: true
)
  JSON.parse(add_scheme(
    name:,
    accepted_responses:,
    should_authenticate:,
  ).body)["data"]["schemeId"]
end

def add_scheme_then_assessor(body:, accepted_responses: [200, 201], assessor_id: "ACME123456")
  add_assessor(
    scheme_id: add_scheme_and_get_id,
    assessor_id:,
    body:,
    accepted_responses:,
  )
end

def add_super_assessor(scheme_id:)
  add_assessor(
    scheme_id:,
    assessor_id: "SPEC000000",
    body: AssessorStub.new.fetch_request_body(
      non_domestic_nos3: "ACTIVE",
      non_domestic_nos4: "ACTIVE",
      non_domestic_nos5: "ACTIVE",
      non_domestic_dec: "ACTIVE",
      domestic_rd_sap: "ACTIVE",
      domestic_sap: "ACTIVE",
      non_domestic_sp3: "ACTIVE",
      non_domestic_cc4: "ACTIVE",
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
    schema_name:,
    migrated:,
    ensure_uprns:,
  )
end

def fetch_renewable_heat_incentive(
  assessment_id:,
  scopes: %w[greendeal:plans],
  headers: {},
  **assertive_kwargs
)
  headers.each { |key, value| header key.to_s, value.to_s }

  assertive_get(
    "api/greendeal/rhi/assessments/#{assessment_id}/latest",
    scopes:,
    **assertive_kwargs,
  )
end

def fetch_assessment(
  id:,
  scopes: %w[assessment:fetch],
  headers: {},
  **assertive_kwargs
)
  headers.each { |key, value| header key.to_s, value.to_s }

  assertive_get(
    "api/assessments/#{id}",
    scopes:,
    **assertive_kwargs,
  )
end

def fetch_assessment_summary(
  id:,
  scopes: %w[assessment:fetch],
  **assertive_kwargs
)
  assertive_get(
    "api/assessments/#{id}/summary",
    scopes:,
    **assertive_kwargs,
  )
end

def fetch_dec_summary(
  assessment_id:,
  scopes: %w[dec_summary:fetch],
  **assertive_kwargs
)
  assertive_get(
    "api/dec_summary/#{assessment_id}",
    scopes:,
    **assertive_kwargs,
  )
end

def assessments_search_by_postcode(
  postcode,
  scopes: %w[assessment:search],
  assessment_types: %w[RdSAP SAP],
  **assertive_kwargs
)
  path = "/api/assessments/search?postcode=#{postcode}"

  unless assessment_types.empty?
    path << "&assessmentTypes=#{assessment_types.sort.join(',')}"
  end

  assertive_get(
    path,
    scopes:,
    **assertive_kwargs,
  )
end

def domestic_assessments_search_by_assessment_id(
  assessment_id,
  scopes: %w[assessment:search],
  **assertive_kwargs
)
  assertive_get(
    "/api/assessments/search?assessmentId=#{assessment_id}",
    scopes:,
    **assertive_kwargs,
  )
end

def assessments_search_by_street_and_town(
  street:,
  town:,
  assessment_types: %w[RdSAP SAP],
  scopes: %w[assessment:search],
  **assertive_kwargs
)
  path = "/api/assessments/search?street=#{street}&town=#{town}"

  unless assessment_types.empty?
    path += "&assessmentTypes=#{assessment_types.sort.join(',')}"
  end

  assertive_get(
    path,
    scopes:,
    **assertive_kwargs,
  )
end

def assessors_search(
  postcode:,
  qualification:,
  scopes: %w[assessor:search],
  **assertive_kwargs
)
  assertive_get(
    "/api/assessors?postcode=#{postcode}&qualification=#{qualification}",
    scopes:,
    **assertive_kwargs,
  )
end

def assessors_search_by_name(
  name,
  qualification_type: nil,
  scopes: %w[assessor:search],
  **assertive_kwargs
)
  assertive_get(
    "/api/assessors?name=#{name}&qualificationType=#{qualification_type}",
    scopes:,
    **assertive_kwargs,
  )
end

def bus_details_by_address(
  postcode:,
  building_name_or_number:,
  scopes: %w[bus:assessment:search],
  **assertive_kwargs
)
  assertive_get(
    "/api/bus/assessments/latest/search?postcode=#{postcode}&buildingNameOrNumber=#{building_name_or_number}",
    scopes:,
    **assertive_kwargs,
  )
end

def bus_details_by_uprn(
  uprn,
  scopes: %w[bus:assessment:search],
  **assertive_kwargs
)
  assertive_get(
    "/api/bus/assessments/latest/search?uprn=#{uprn}",
    scopes:,
    **assertive_kwargs,
  )
end

def bus_details_by_rrn(
  rrn,
  scopes: %w[bus:assessment:search],
  **assertive_kwargs
)
  assertive_get(
    "/api/bus/assessments/latest/search?rrn=#{rrn}",
    scopes:,
    **assertive_kwargs,
  )
end

def bus_details_by_arbitrary_params(
  params:,
  scopes: %w[bus:assessment:search],
  **assertive_kwargs
)
  assertive_get(
    "/api/bus/assessments/latest/search?#{URI.encode_www_form(params)}",
    scopes:,
    **assertive_kwargs,
  )
end

def eco_plus_details_by_rrn(
  rrn,
  scopes: %w[ecoplus:assessment:fetch],
  **assertive_kwargs
)
  assertive_get(
    "/api/ecoplus/assessments/#{rrn}",
    scopes:,
    **assertive_kwargs,
  )
end

def retrofit_funding_details_by_uprn(
  uprn,
  scopes: %w[retrofit-funding:assessment:fetch],
  **assertive_kwargs
)
  assertive_get(
    "/api/retrofit-funding/assessments?uprn=#{uprn}",
    scopes:,
    **assertive_kwargs,
  )
end

def hera_details_by_rrn(
  rrn,
  scopes: %w[retrofit-advice:assessment:fetch],
  **assertive_kwargs
)
  assertive_get(
    "/api/retrofit-advice/assessments/#{rrn}",
    scopes:,
    **assertive_kwargs,
  )
end

def heat_pump_check_details_by_rrn(
  rrn,
  scopes: ["heat-pump-check:assessment:fetch"],
  **assertive_kwargs
)
  assertive_get(
    "/api/heat-pump-check/assessments/#{rrn}",
    scopes:,
    **assertive_kwargs,
  )
end

def warm_home_discount_details_by_rrn(
  rrn,
  scopes: %w[warm-home-discount:assessment:fetch],
  **assertive_kwargs
)
  assertive_get(
    "/api/warm-home-discount/assessments/#{rrn}",
    scopes:,
    **assertive_kwargs,
  )
end

def warm_home_discount_details_by_rrn_with_property_type(
  rrn,
  scopes: %w[warm-home-discount:assessment:fetch],
  param_value: "true",
  **assertive_kwargs
)
  assertive_get(
    "/api/warm-home-discount/assessments/#{rrn}?includeTypeOfProperty=#{param_value}",
    scopes:,
    **assertive_kwargs,
  )
end

def find_domestic_epcs_with_params(
  params:,
  scopes: %w[assessment:domestic-epc:search],
  **assertive_kwargs
)
  assertive_get(
    "/api/assessments/domestic-epcs/search?#{URI.encode_www_form(params)}",
    scopes:,
    **assertive_kwargs,
  )
end

def schemes_list(
  scopes: %w[scheme:list],
  **assertive_kwargs
)
  assertive_get(
    "/api/schemes",
    scopes:,
    **assertive_kwargs,
  )
end

def address_search_by_id(
  address_id,
  scopes: %w[address:search],
  **assertive_kwargs
)
  assertive_get(
    "/api/search/addresses?addressId=#{address_id}",
    scopes:,
    **assertive_kwargs,
  )
end

def address_search_by_postcode(
  postcode,
  scopes: %w[address:search],
  **assertive_kwargs
)
  assertive_get(
    "/api/search/addresses?postcode=#{postcode}",
    scopes:,
    **assertive_kwargs,
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

  assertive_get(
    url,
    accepted_responses:,
    should_authenticate: authenticate,
    auth_data:,
    scopes:,
  )
end

def opt_out_assessment(
  assessment_id:,
  opt_out: true,
  scopes: %w[admin:opt_out],
  **assertive_kwargs
)
  assertive_put(
    "/api/assessments/#{assessment_id}/opt-out",
    body: { "optOut": opt_out },
    scopes:,
    accepted_responses: [200],
    **assertive_kwargs,
  )
end

def update_assessment_address_id(
  assessment_id:,
  new_address_id:,
  accepted_responses: [200],
  scopes: %w[admin:update-address-id],
  **assertive_kwargs
)
  assertive_put(
    "/api/assessments/#{assessment_id}/address-id",
    body: { "addressId": new_address_id },
    accepted_responses:,
    scopes:,
    **assertive_kwargs,
  )
end

def fetch_assessment_meta_data(
  assessment_id:,
  scopes:, accepted_responses: [200],
  authenticate: true,
  auth_data: {}
)
  assertive_get(
    "/api/assessments/#{assessment_id}/meta-data",
    accepted_responses:,
    should_authenticate: authenticate,
    auth_data:,
    scopes:,
  )
end

def fetch_statistics(
  scopes:, accepted_responses: [200],
  authenticate: true,
  auth_data: {}
)
  assertive_get(
    "/api/statistics",
    accepted_responses:,
    should_authenticate: authenticate,
    auth_data:,
    scopes:,
  )
end

def fetch_statistics_new(
  scopes:, accepted_responses: [200],
  authenticate: true,
  auth_data: {}

)
  assertive_get(
    "/api/statistics/new",
    accepted_responses:,
    should_authenticate: authenticate,
    auth_data:,
    scopes:,
  )
end

def assertive_get_in_search_scope(path, accepted_responses: [200])
  assertive_get(
    path,
    scopes: %w[address:search],
    accepted_responses:,
  )
end
