module Controller
  class SchemesController < Controller::BaseController
        POST_SCHEMA = {
        type: 'object',
        required: %w[name],
        properties: {name: {type: 'string'}}
    }

    get '/api/schemes' do
      content_type :json
      all_schemes = @container.get_object(:get_all_schemes_use_case).execute
      @json_helper.convert_to_json(all_schemes)
    end

    post '/api/schemes' do
      content_type :json
      request_body = @json_helper.convert_to_ruby_hash(request.body.read.to_s, POST_SCHEMA)
      result =
          @container.get_object(:add_new_scheme_use_case).execute(
              request_body[:name]
          )

      status 201
      @json_helper.convert_to_json(result)
    rescue Exception => e
      case e
      when JSON::Schema::ValidationError, JSON::ParserError
        status 401
        single_error_response('INVALID REQUEST', e.message)
      when Gateway::SchemesGateway::DuplicateSchemeException
        status 400
        single_error_response('DUPLICATE_SCHEME', 'Scheme with this name already exists')
      else
        status 500
        single_error_response('SERVER_ERROR', e.message)
      end
    end

    private
  end
end
