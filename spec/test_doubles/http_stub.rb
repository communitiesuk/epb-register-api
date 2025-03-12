require "webmock"

class HttpStub
  OAUTH_TOKEN =
    "eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjE1OTc3NzU5NDAsImlhdCI6MTU5Nzc3MjM0MCwiaXNzIjoidGVzdC1pc3N1ZXIiLCJzdWIiOiJ0ZXN0LXN1YiJ9.RyXrSxCzEgnepsYEft8YP5W6tKUAlcVnS_83FGDMy3Y"
      .freeze
  S3_BUCKET_URI = "https://s3.eu-west-2.amazonaws.com/test_bucket/".freeze

  def self.s3_get_object(key, body = "", code = 200)
    WebMock.stub_request(
      :get,
      "https://test-bucket.s3.eu-west-2.amazonaws.com/#{key}",
    ).to_return status: code,
                body:
  end

  def self.s3_put_csv(file_name)
    WebMock.enable!
    WebMock.reset!
    uri = "#{S3_BUCKET_URI}#{file_name}"
    WebMock.stub_request(:put, uri).to_return(status: 200)
  end

  def self.off
    WebMock.disable!

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
