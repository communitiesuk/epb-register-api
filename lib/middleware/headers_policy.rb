# frozen_string_literal: true

module Middleware
  SITE_POLICY = ""

  class HeadersPolicy
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers["Strict-Transport-Security"] = "max-age=300; includeSubDomains; preload"
      headers.delete "x-frame-options"
      headers.delete "x-xss-protection"
      [status, headers, body]
    end
  end
end
