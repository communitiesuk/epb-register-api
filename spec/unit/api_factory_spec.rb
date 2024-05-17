describe ApiFactory do
  before do
    EnvironmentStub.with("AWS_ACCESS_KEY_ID", "123456")
    EnvironmentStub.with("AWS_SECRET_ACCESS_KEY", "dsadsasaffsasaf")
  end

  after do
    EnvironmentStub.remove(%w[AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY])
  end

  it "checks all the factory methods can execute correctly" do
    described_class.methods(false).each do |method|
      if described_class.method(method).arity.zero?
        expect { described_class.send method }.not_to raise_error
      else
        args = {}
        params = described_class.method(method).parameters.first.reject { |i| i == :keyreq }
        params.each do |i|
          args[i] = "#{i}_value"
        end

        expect { described_class.send(method, **args) }.not_to raise_error
      end
    end
  end
end
