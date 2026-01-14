class RegisterApiService < Controller::BaseController
  options "*" do
    response.headers["Allow"] = "HEAD,GET,PUT,DELETE,OPTIONS"
    response.headers["Access-Control-Allow-Methods"] =
      "HEAD, GET, PUT, OPTIONS, DELETE, POST"
    unless ENV["EPB_API_DOCS_URL"].nil?
      response.headers["Access-Control-Allow-Origin"] = ENV["EPB_API_DOCS_URL"]
    end

    200
  end

  get "/" do
    redirect "/api"
  end

  get "/api" do
    content_type :json

    {
      api: {
        title: "Energy Performance of Buildings Register",
        links: {
          describedBy: "https://api-docs.epcregisters.net",
        },
      },
    }.to_json
  end

  get "/healthcheck" do
    status 200
  end

  use Controller::AssessorController
  use Controller::AddressSearchController
  use Controller::BoilerUpgradeSchemeController
  use Controller::SchemesController
  use Controller::EnergyAssessmentController
  use Controller::GreenDealPlanController
  use Controller::AssessmentStatusController
  use Controller::AssessmentSummaryController
  use Controller::AssessorStatusController
  use Controller::DecSummaryController
  use Controller::ReportingController
  use Controller::AssessmentMetaController
  use Controller::StatisticsController
  use Controller::DomesticEpcSearchController
  use Controller::DomesticInitiativesController
  use Controller::RetrofitFundingSchemeController
  use Controller::CertificateSummaryController
  use Controller::PrsDatabaseController
  use Controller::ScotlandController
end
