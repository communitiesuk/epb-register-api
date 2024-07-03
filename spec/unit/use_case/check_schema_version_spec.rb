describe UseCase::CheckSchemaVersion do
  subject(:use_case) { described_class.new(logger:) }

  let(:logger) { instance_spy Logger }

  before do
    allow(logger).to receive(:error)
    allow(ENV).to receive(:[])
    allow(ENV).to receive(:[]).with("VALID_DOMESTIC_SCHEMAS").and_return("SAP-Schema-19.1.0,SAP-Schema-19.0.0,SAP-Schema-18.0.0,RdSAP-Schema-NI-19.0")
    allow(ENV).to receive(:[]).with("VALID_NON_DOMESTIC_SCHEMAS").and_return("CEPC-8.0.0")
  end

  it "can load the class" do
    expect { use_case }.not_to raise_exception
  end

  it "returns false for an invalid schema version" do
    expect(use_case.execute("SAP-Schema-17.0.0")).to be(false)
  end

  it "returns true for a valid SAP schema version" do
    expect(use_case.execute("SAP-Schema-19.0.0")).to be(true)
  end

  it "returns true for the latest SAP schema version" do
    expect(use_case.execute("SAP-Schema-19.1.0")).to be(true)
  end

  it "returns true for the latest CEPC schema version" do
    expect(use_case.execute("CEPC-8.0.0")).to be(true)
  end

  it "returns true for the latest NI RdSAP schema version" do
    expect(use_case.execute("RdSAP-Schema-NI-19.0")).to be(true)
  end

  it "returns false when ENV is not available" do
    allow(ENV).to receive(:[]).with("VALID_DOMESTIC_SCHEMAS").and_return(nil)
    allow(ENV).to receive(:[]).with("VALID_NON_DOMESTIC_SCHEMAS").and_return(nil)
    expect(use_case.execute("RdSAP-Schema-NI-19.0")).to be(false)
  end

  it "logs the error when when ENV is no available" do
    allow(ENV).to receive(:[]).with("VALID_DOMESTIC_SCHEMAS").and_return(nil)
    allow(ENV).to receive(:[]).with("VALID_NON_DOMESTIC_SCHEMAS").and_return(nil)
    use_case.execute("RdSAP-Schema-NI-19.0")
    expect(logger).to have_received(:error)
  end

  it "strips any unintended whitespace from the lists of schemas" do
    allow(ENV).to receive(:[]).with("VALID_DOMESTIC_SCHEMAS").and_return("SAP-Schema-19.0.0, SAP-Schema-18.0.0, RdSAP-Schema-NI-19.0")
    allow(ENV).to receive(:[]).with("VALID_NON_DOMESTIC_SCHEMAS").and_return("CEPC-8.0.0, CEPC-NI-8.0.0")

    expect(use_case.execute("SAP-Schema-18.0.0")).to be(true)
    expect(use_case.execute("RdSAP-Schema-NI-19.0")).to be(true)
    expect(use_case.execute("CEPC-NI-8.0.0")).to be(true)
  end
end
