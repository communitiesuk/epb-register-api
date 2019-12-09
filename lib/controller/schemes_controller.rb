module Controller
  class SchemesController < Sinatra::Base
    STATUS_CODES = {
      '400' => [PG::UniqueViolation, ActiveRecord::RecordNotUnique],
      '401' => [JSON::ParserError]
    }.freeze

    def initialize(toggles = false)
      super
      @json_helper = Helper::JsonHelper.new
      @toggles = toggles || Toggles.new
      @container = Container.new
    end

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
