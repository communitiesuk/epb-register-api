class EnvironmentStub
  @environments = []

  def self.all
    @environments.each { |env| ENV[env] = nil }

    ENV["BUCKET_NAME"] = "test_bucket"
    ENV["AWS_ACCESS_KEY_ID"] = "AKIAIOSFODNN7EXAMPLE"
    ENV["AWS_SECRET_ACCESS_KEY"] = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    ENV["AWS_DEFAULT_REGION"] = "eu-west-1"
    ENV["AWS_REGION"] = "eu-west-1"
    self
  end

  def self.except(variable)
    ENV[variable] = nil
    self
  end

  def self.with(variable, value)
    ENV[variable] = value
    @environments << variable

    self
  end
end
