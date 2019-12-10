module Controller
  class SchemesController < Controller::BaseController
    POST_SCHEMA = {
      type: 'object',
      required: %w[name],
      properties: { name: { type: 'string' } }
    }

    get '/api/schemes' do
      all_schemes = @container.get_object(:get_all_schemes_use_case).execute
      json_response(200, all_schemes)
    end

    post '/api/schemes' do
      request_body = request_body(POST_SCHEMA)
      result =
        @container.get_object(:add_new_scheme_use_case).execute(
          request_body[:name]
        )
      json_response(201, result)
    rescue Exception => e
      case e
      when JSON::Schema::ValidationError, JSON::ParserError
        status 401
        single_error_response('INVALID REQUEST', e.message)
      when Gateway::SchemesGateway::DuplicateSchemeException
        status 400
        single_error_response(
          'DUPLICATE_SCHEME',
          'Scheme with this name already exists'
        )
      else
        status 500
        single_error_response('SERVER_ERROR', e.message)
      end
    end
  end
end
