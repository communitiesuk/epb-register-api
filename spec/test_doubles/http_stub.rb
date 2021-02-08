require "webmock"

class HttpStub
  OAUTH_TOKEN =
    "eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjE1OTc3NzU5NDAsImlhdCI6MTU5Nzc3MjM0MCwiaXNzIjoidGVzdC1pc3N1ZXIiLCJzdWIiOiJ0ZXN0LXN1YiJ9.RyXrSxCzEgnepsYEft8YP5W6tKUAlcVnS_83FGDMy3Y"
      .freeze

  def self.s3_get_object(key, body = "", code = 200)
    WebMock.stub_request(
      :get,
      "https://test-bucket.s3.eu-west-1.amazonaws.com/#{key}",
    ).to_return status: code,
                body:
                                                                                                   body
  end

  def self.s3_put_object(key, _body = "", error = nil, code = 200)
    mock =
      WebMock.stub_request(
        :put,
        "https://test-bucket.s3.eu-west-1.amazonaws.com/#{key}",
      )
    if error
      mock.to_raise(error)
    else
      mock.to_return status: code, body: ""
    end
  end

  def self.s3_objects(objects = [])
    file = Tempfile.new("file_list")

    objects.each do |object|
      s3_get_object object[:key], (object[:body] || ""), object[:code] || 200
      file.write("#{object[:key]}\n")
    end

    file.close

    file.path
  end

  def self.successful_assessor_create(
    scheme_id,
    assessor_id,
    first_name,
    last_name,
    dob
  )
    WebMock.enable!

    WebMock
      .stub_request(
        :put,
        "http://test-register/api/schemes/#{scheme_id}/assessors/#{assessor_id}",
      )
      .with(
        body:
          JSON.generate(
            { firstName: first_name, lastName: last_name, dateOfBirth: dob },
          ),
      ).to_return status: 201
  end

  def self.successful_lodgement(body: nil, assessor_created: false)
    WebMock.enable!

    options = { headers: { "Authorization" => "Bearer #{OAUTH_TOKEN}" } }

    options[:body] = body if body

    WebMock
      .stub_request(
        :post,
        "http://test-register/api/assessments?migrated&assessor_created=#{assessor_created}",
      )
      .with(options).to_return status: 200,
                               body:
                 JSON.generate(
                   data: {
                     assessments: %w[
                       9881-300-0219-0300-5225
                       0580-0341-8299-1021-2006
                     ],
                   },
                   meta: {
                     links: {
                       assessments: %w[
                         /api/assessments/9881-3001-0219-0300-5225
                         /api/assessments/0580-0341-8299-1021-2006
                       ],
                     },
                   },
                 ),
                               headers: {
                                 "Content-Type" => "application/json",
                               }
  end

  def self.failed_lodgement(
    error = nil,
    error_response = nil,
    assessor_created: false
  )
    WebMock.enable!

    stub =
      WebMock.stub_request(
        :post,
        "http://test-register/api/assessments?migrated&assessor_created=#{assessor_created}",
      )

    if error
      stub.to_raise error
    else
      response = {
        errors: [
          {
            code: "INVALID_REQUEST",
            title:
              "4:0: ERROR: Element '{https://epbr.digital.communities.gov.uk/xsd/cepc}Reports': No matching global declaration available for the validation root.",
          },
        ],
      }

      response = error_response unless error_response.nil?

      # to_return(body: lambda { |request| request.body })
      stub.to_return status: 400,
                     body: JSON.generate(response),
                     headers: {
                       "Content-Type" => "application/json",
                     }
    end
  end

  def self.successful_status_update(assessment_id, status)
    WebMock.enable!

    WebMock
      .stub_request(
        :post,
        "http://test-register/api/assessments/#{assessment_id}/status",
      )
      .with(
        body: JSON.generate(status: status),
        headers: {
          "Authorization" => "Bearer #{OAUTH_TOKEN}",
        },
      ).to_return status: 200,
                  body: JSON.generate(status: status),
                  headers: {
                    "Content-Type" => "application/json",
                  }
  end

  def self.unsuccessful_status_update(assessment_id, status)
    WebMock.enable!

    WebMock
      .stub_request(
        :post,
        "http://test-register/api/assessments/#{assessment_id}/status",
      )
      .with(
        body: JSON.generate(status: status),
        headers: {
          "Authorization" => "Bearer #{OAUTH_TOKEN}",
        },
      ).to_return status: 404,
                  body:
                 JSON.generate(
                   {
                     errors: [
                       { code: "NOT_FOUND", title: "Assessment not found" },
                     ],
                   },
                 ),
                  headers: {
                    "Content-Type" => "application/json",
                  }
  end

  def self.successful_token
    WebMock.enable!

    WebMock.stub_request(
      :post,
      "http://test-auth/oauth/token",
    ).to_return status: 200,
                body:
                                                                           JSON
                                                                             .generate(
                                                                               access_token:
                                                                                 OAUTH_TOKEN,
                                                                               expires_in:
                                                                                 3_600,
                                                                               token_type:
                                                                                 "bearer",
                                                                             ),
                headers: {
                  "Content-Type" =>
                    "application/json",
                }
  end

  def self.failed_token
    WebMock.enable!

    WebMock.stub_request(
      :post,
      "http://test-auth/oauth/token",
    ).to_return status: 401,
                body:
                                                                           JSON
                                                                             .generate(
                                                                               code:
                                                                                 "NOT_AUTHENTICATED",
                                                                               message:
                                                                                 "Boundary::NotAuthenticatedError",
                                                                             ),
                headers: {
                  "Content-Type" =>
                    "application/json",
                }
  end

  def self.off
    WebMock.disable!

    self
  end

  def self.enable_aws
    ENV["AWS_ACCESS_KEY_ID"] = "AKIAIOSFODNN7EXAMPLE"
    ENV["AWS_SECRET_ACCESS_KEY"] = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    ENV["AWS_DEFAULT_REGION"] = "eu-west-1"
    ENV["AWS_REGION"] = "eu-west-1"

    enable_webmock

    self
  end

  def self.enable_logging
    WebMock
      .stub_request(:post, "https://api.logit.io/v2")
      .to_return(status: 200, body: "", headers: {})
  end

  def self.disable_logging
    WebMock.stub_request(
      :post,
      "https://api.logit.io/v2",
    ).to_raise StandardError
  end

  def self.disable_aws
    ENV["AWS_ACCESS_KEY_ID"] = nil
    ENV["AWS_SECRET_ACCESS_KEY"] = nil
    ENV["AWS_DEFAULT_REGION"] = nil
    ENV["AWS_REGION"] = nil

    enable_webmock

    self
  end

  def self.enable_webmock
    WebMock.enable!
    WebMock.reset!

    WebMock.stub_request(
      :any,
      %r{http://169.254.169.254/.*},
    ).to_raise StandardError
  end
end
