module Controller
  class SchemesController < Controller::BaseController
    STATUS_CODES = {
      '400' => [PG::UniqueViolation, ActiveRecord::RecordNotUnique],
      '401' => [JSON::ParserError]
    }.freeze

    get '/api/schemes' do
      content_type :json
      all_schemes = @container.get_object(:get_all_schemes_use_case).execute
      @json_helper.convert_to_json(all_schemes)
    end

    post '/api/schemes' do
      content_type :json
      request_body = @json_helper.convert_to_ruby_hash(request.body.read.to_s)
      result =
        @container.get_object(:add_new_scheme_use_case).execute(
          request_body[:name]
        )

      status 201
      @json_helper.convert_to_json(result)
    rescue StandardError => e
      handle_exception(e)
    end

    private

    def handle_exception(error)
      return status 400 if STATUS_CODES['400'].include?(error.class)
      return status 401 if STATUS_CODES['401'].include?(error.class)

      status 500
    end
  end
end
