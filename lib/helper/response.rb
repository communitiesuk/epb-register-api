module Helper
  module Response
    def self.ensure_good(&block)
      begin
        response = yield block
      rescue Faraday::TimeoutError => e
        # raise a timeout error straight away
        raise Errors::RequestTimeoutError,
              sprintf(
                'API request timed out. Message from %s: "%s"',
                e.class,
                e.message,
              )
      rescue Auth::Errors::NetworkConnectionFailed
        # try once again on a possibly transient network error
        begin
          response = yield block
        rescue StandardError => e
          raise Errors::ConnectionApiError,
                sprintf(
                  'Connection to API failed, even after retry. Message from %s: "%s"',
                  e.class,
                  e.message,
                )
        end
      end

      ensure_is_response response

      if response.status == 401
        raise Errors::ApiAuthorizationError,
              sprintf('Authorization issue with internal API. Response body: "%s"', response.body)
      end
      ensure_json response.body

      unless response.status < 400 ||
          JSON.parse(response.body, symbolize_names: true)[:error]
        raise Errors::MalformedErrorResponseError,
              sprintf(
                'Internal API response of status code %s had no errors node. Response body: "%s"',
                response.status,
                response.body,
              )
      end

      response
    end

    def self.ensure_json(content)
      return if check_valid_json content

      raise Errors::NonJsonResponseError,
            sprintf('Response did not contain JSON: "%s"', content)
    end

    def self.check_valid_json(content)
      JSON.parse(content)
      true
    rescue JSON::ParserError
      false
    end

    def self.ensure_is_response(response)
      return if %i[status body].all? { |method| response.respond_to? method }

      raise Errors::ResponseNotPresentError,
            sprintf(
              "Response object was expected from call on internal HTTP client, object of type %s returned instead.", response.class
            )
    end
  end
end
