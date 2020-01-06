class AssessorService < Controller::BaseController
  options '*' do
    response.headers['Allow'] = 'HEAD,GET,PUT,DELETE,OPTIONS'
    response.headers['Access-Control-Allow-Methods'] =
      'HEAD, GET, PUT, OPTIONS, DELETE, POST'
    200
  end

  get '/' do
    redirect '/api'
  end

  get '/api' do
    content_type :json

    {
      links: { apispec: 'https://mhclg-epb-swagger.london.cloudapps.digital' }
    }.to_json
  end

  get '/healthcheck' do
    status 200
  end

  use Controller::AssessorController
  use Controller::SchemesController
  use Controller::FindAssessorController
end
