module Controller
  class FindAssessorController < Controller::BaseController
    get '/api/findassessor/:postcode', jwt_auth: [] do
      body '1'
    end
  end
end
