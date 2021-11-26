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

  context "when parsing a domain object from json" do
    let(:json) do
      Domain::CustomerSatisfaction.new(Time.new(2021, 11, 23), 1, 2, 3, 4, 5).to_json
    end

    it "convert json back to object and passed to use case without error" do
      object = JSON.parse(json, object_class: OpenStruct)
      expect { use_case.execute(object) }.not_to raise_error
    end
  end

  context "when parsing a domain object with a badly formed date" do
    let(:json) do
      { "stats_date" => "1",
        "satisfied" => 2,
        "very_satisfied" => 1,
        "neither" => 3,
        "dissatisfied" => 4,
        "very_dissatisfied" => 5 }.to_json
    end

    it "raises an invalid date date error" do
      object = JSON.parse(json, object_class: OpenStruct)
      expect { use_case.execute(object) }.to raise_error(Boundary::InvalidDate)
    end
  end

  context "when parsing a hash that cannot be converting to the domain object" do
    let(:json) do
      { "stats_date" => Time.now }.to_json
    end

    it "raises an argument error" do
      object = JSON.parse(json, object_class: OpenStruct)
      expect { use_case.execute(object) }.to raise_error(Boundary::ArgumentMissing)
    end

    it "raises an argument error for a specific missing key" do
      data = { "stats_date" => datetime_today,
               "something" => 2,
               "very_satisfied" => 1,
               "neither" => 3,
               "dissatisfied" => 4,
               "very_dissatisfied" => 5 }.to_json
      object = JSON.parse(data, object_class: OpenStruct)
      expect { use_case.execute(object) }.to raise_error(Boundary::ArgumentMissing, "A required argument is missing: satisfied")
    end
  end
end
