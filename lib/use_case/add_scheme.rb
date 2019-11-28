class AddScheme
  def initialize(gateway)
    @gateway = gateway
  end

  def execute(name)
    @gateway.add_scheme(name)
  end
end
