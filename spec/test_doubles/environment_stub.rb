class EnvironmentStub
  @environments = []

  def self.all
    @environments.each { |env| ENV[env] = nil }
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
