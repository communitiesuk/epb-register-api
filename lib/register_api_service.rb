class RegisterApiService < Controller::BaseController
  def initialize(toggles = nil)
    super
    @toggles = Helper::Toggles.new
  end

  options "*" do
    response.headers["Allow"] = "HEAD,GET,PUT,DELETE,OPTIONS"
    response.headers["Access-Control-Allow-Methods"] =
      "HEAD, GET, PUT, OPTIONS, DELETE, POST"
    200
  end

  get "/" do
    redirect "/api"
  end

  get "/api" do
    content_type :json

    {
      links: { apispec: "https://mhclg-epb-swagger.london.cloudapps.digital" },
    }.to_json
  end

  get "/healthcheck" do
    status 200
  end

  use Controller::AssessorController
  use Controller::AddressSearchController
  use Controller::SchemesController
  use Controller::EnergyAssessmentController
  use Controller::GreenDealPlanController
  use Controller::AssessmentStatusController
  use Controller::AssessmentSummaryController
  use Controller::AssessorStatusController
  use Controller::DecSummaryController
  use Controller::ReportingController
end
