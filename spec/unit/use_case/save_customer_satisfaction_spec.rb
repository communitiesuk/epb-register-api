describe UseCase::SaveCustomerSatisfaction do
  subject(:use_case) { described_class.new(gateway) }

  let(:gateway) do
    instance_double(Gateway::CustomerSatisfactionGateway)
  end

  let(:domain_object) do
    Domain::CustomerSatisfaction.new(Time.new(2021, 9, 0o5), 755, 125, 51, 69, 81)
  end

  before do
    allow(gateway).to receive(:upsert)
  end

  it "instantiates the class without error" do
    expect { use_case }.not_to raise_error
  end

  it "calls the correct gateway method" do
    use_case.execute(domain_object)
    expect(gateway).to have_received(:upsert).with(domain_object).exactly(1).times
  end

  it "raises a error if the argument passed in not the the correct domian object" do
    expect { use_case.execute("domain_object") }.to raise_error(ArgumentError)
    expect { use_case.execute(gateway) }.to raise_error(ArgumentError)
  end
end
