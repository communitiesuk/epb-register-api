module UseCase
  class AddScheme
    def initialize(gateway)
      @gateway = gateway
    end

    def execute(name)
      @gateway.add(name)
    end
  end
end
