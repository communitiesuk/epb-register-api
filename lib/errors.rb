module Errors
  class ApiError < StandardError
  end

  class ApiResponseError < ApiError
  end

  class NonJsonResponseError < ApiError
  end

  class ApiAuthorizationError < ApiError
  end

  class MalformedErrorResponseError < ApiError
  end

  class MalformedResponseError < ApiError
  end

  class ResponseNotPresentError < ApiError
  end

  class ConnectionApiError < ApiError
  end

  class RequestTimeoutError < ConnectionApiError
  end

  class InternalServerError < ApiError
  end

  class MissingRequiredParameterError < StandardError
  end
end
