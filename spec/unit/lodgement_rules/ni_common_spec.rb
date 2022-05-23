describe LodgementRules::NiCommon do
  subject(:ni_common) { described_class.new }

  let(:ni_address) do
    { postcode: "BT10 1AA" }
  end
  let(:england_address) do
    { postcode: "SW1 1AA" }
  end

  it "loads the class without error" do
    expect { ni_common }.not_to raise_error
  end

  describe "#validate" do
    context "when schema is not  Northern Ireland" do
      it "does not raise an error" do
        expect { ni_common.validate(schema_name: "RdSAP-Schema-20.0.0", address: england_address) }.not_to raise_error
      end

      it "raise an error with a NI postcode", :aggregate_failures do
        expect { ni_common.validate(schema_name: "RdSAP-Schema-20.0.0", address: ni_address) }.to raise_error Boundary::InvalidNiAssessment, /Assessment with a Northern Ireland postcode must be lodged with a NI Schema/
        expect { ni_common.validate(schema_name: "RdSAP-Schema-20.0.0", address: { postcode: "bt1 1AA" }) }.to raise_error Boundary::InvalidNiAssessment
        expect { ni_common.validate(schema_name: "RdSAP-Schema-20.0.0", address: { postcode: " BT3 1AA" }) }.to raise_error Boundary::InvalidNiAssessment
      end
    end

    context "when schema is in Northern Ireland" do
      it "raises an error with an non NI postcode" do
        expect { ni_common.validate(schema_name: "RdSAP-Schema-NI-20.0.0", address: england_address) }.to raise_error Boundary::InvalidNiAssessment, /Assessment with a Northern Ireland schema must have a property postcode starting with BT/
      end

      it "does not raises an error with an NI postcode", :aggregate_failures do
        expect { ni_common.validate(schema_name: "RdSAP-Schema-NI-20.0.0", address: ni_address) }.not_to raise_error
        expect { ni_common.validate(schema_name: "SAP-Schema-NI-19.0.0", address: ni_address) }.not_to raise_error
      end
    end

    context "when validation  rule is overwritten by migrated=true" do
      it "does not raise an error for NI Schemas" do
        expect { ni_common.validate(schema_name: "RdSAP-Schema-NI-20.0.0", address: england_address, migrated: true) }.not_to raise_error
      end

      it "does not raise an error with an NI postcode", :aggregate_failures do
        expect { ni_common.validate(schema_name: "RdSAP-Schema-20.0.0", address: ni_address, migrated: true) }.not_to raise_error
      end
    end
  end
end
