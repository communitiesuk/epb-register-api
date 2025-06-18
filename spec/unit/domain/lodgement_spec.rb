describe Domain::Lodgement do
  let(:border_domain) do
    Domain::CountryLookup.new(country_codes: %i[E W])
  end

  let(:english_domain) do
    Domain::CountryLookup.new(country_codes: [:E])
  end

  let(:cepc) do
    Samples.xml "CEPC-8.0.0", "dec-rr"
  end

  describe "#fetch_data" do
    context "when an RdSAP is passed" do
      let(:xml) { Samples.xml "RdSAP-Schema-20.0.0" }
      let(:domain) { described_class.new(xml, "RdSAP-Schema-20.0.0") }

      it "returns an assessment hash in an array" do
        expect(domain.fetch_data).to be_a Array
        expect(domain.fetch_data.first[:assessment_id]).to eq("0000-0000-0000-0000-0000")
      end

      it "has a country_id for England" do
        domain.add_country_id_to_data(1)
        expect(domain.fetch_data[0][:country_id]).to eq 1
      end
    end

    context "when a CEPC with dual lodgement is passed" do
      let(:xml) { Samples.xml "CEPC-8.0.0", "cepc+rr" }

      let(:domain) { described_class.new(xml, "CEPC-8.0.0") }

      it "return an array of assessments" do
        expect(domain.fetch_data.length).to eq 2
        expect(domain.fetch_data.first[:assessment_id]).to eq("0000-0000-0000-0000-0000")
        expect(domain.fetch_data[1][:assessment_id]).to eq("0000-0000-0000-0000-0001")
      end

      it "has a country_id for England" do
        domain.add_country_id_to_data(2)
        expect(domain.fetch_data.first[:country_id]).to eq 2
      end
    end
  end

  describe "#fetch_country_id" do
    let(:xml) { Samples.xml "RdSAP-Schema-20.0.0" }

    it "fetches the country_id from assessment data" do
      domain = described_class.new(xml, "RdSAP-Schema-20.0.0")
      domain.add_country_id_to_data(1)
      expect(domain.fetch_country_id).to eq 1
    end

    it "fetches nil from the country_id" do
      domain_one = described_class.new(xml, "RdSAP-Schema-20.0.0")
      expect(domain_one.fetch_country_id).to be_nil
    end
  end

  describe "#country_code" do
    it "returns the country code from an RdSAP" do
      xml = Samples.xml "RdSAP-Schema-20.0.0"
      domain = described_class.new(xml, "RdSAP-Schema-20.0.0")
      expect(domain.country_code).to eq("EAW")
    end

    it "returns the country code from an RdSAP 21.0.0" do
      xml = Samples.xml "RdSAP-Schema-21.0.0"
      domain = described_class.new(xml, "RdSAP-Schema-21.0.0")
      expect(domain.country_code).to eq("ENG")
    end

    it "returns the country code from an RdSAP 21.0.1" do
      xml = Samples.xml "RdSAP-Schema-21.0.1"
      domain = described_class.new(xml, "RdSAP-Schema-21.0.1")
      expect(domain.country_code).to eq("ENG")
    end

    it "returns the country code from a SAP 19.1.0" do
      xml = Samples.xml "SAP-Schema-19.1.0"
      domain = described_class.new(xml, "SAP-Schema-19.1.0")
      expect(domain.country_code).to eq("ENG")
    end
  end

  describe "#schema_version" do
    let(:xml) { Samples.xml "RdSAP-Schema-20.0.0" }

    it "returns decimal of the RdSAP schema version" do
      domain = described_class.new(xml, "RdSAP-Schema-20.0.0")
      expect(domain.schema_version).to eq 20.0
    end

    it "returns decimal of the CEPC schema version" do
      domain = described_class.new(cepc, "CEPC-8.0.0")
      expect(domain.schema_version).to eq 8.0
    end
  end

  describe "#is_new_rdsap?" do
    it "returns true for RdSAP-Schema-21.0.0" do
      xml = Samples.xml "RdSAP-Schema-21.0.0"
      domain = described_class.new(xml, "RdSAP-Schema-21.0.0")
      expect(domain.is_new_rdsap?).to be true
    end

    it "returns true for RdSAP-Schema-21.0.1" do
      xml = Samples.xml "RdSAP-Schema-21.0.1"
      domain = described_class.new(xml, "RdSAP-Schema-21.0.1")
      expect(domain.is_new_rdsap?).to be true
    end

    it "returns true for RdSAP-Schema-NI-21.0.0" do
      xml = Samples.xml "RdSAP-Schema-NI-21.0.0"
      domain = described_class.new(xml, "RdSAP-Schema-NI-21.0.0")
      expect(domain.is_new_rdsap?).to be true
    end

    it "returns false for RdSAP-Schema-20.0.0" do
      xml = Samples.xml "RdSAP-Schema-20.0.0"
      domain = described_class.new(xml, "RdSAP-Schema-20.0.0")
      expect(domain.is_new_rdsap?).to be false
    end

    it "returns false for CEPC" do
      domain = described_class.new(cepc, "CEPC-8.0.0")
      expect(domain.is_new_rdsap?).to be false
    end
  end

  describe "#is_new_sap?" do
    it "returns true for SAP-Schema-19.0.0" do
      xml = Samples.xml "SAP-Schema-19.0.0"
      domain = described_class.new(xml, "SAP-Schema-19.0.0")
      expect(domain.is_new_sap?).to be true
    end

    it "returns false for SAP-Schema-18.0.0" do
      xml = Samples.xml "SAP-Schema-18.0.0"
      domain = described_class.new(xml, "SAP-Schema-18.0.0")
      expect(domain.is_new_rdsap?).to be false
    end

    it "returns false for RdSAP which contasin string 'SAP'" do
      xml = Samples.xml "RdSAP-Schema-20.0.0"
      domain = described_class.new(xml, "RdSAP-Schema-20.0.0")
      expect(domain.is_new_rdsap?).to be false
    end
  end

  describe "#is_sap_17_or_18?" do
    it "returns true for SAP-Schema-18.0.0" do
      xml = Samples.xml "SAP-Schema-18.0.0"
      domain = described_class.new(xml, "SAP-Schema-18.0.0")
      expect(domain.is_sap_17_or_18?).to be true
    end

    it "returns true for SAP-Schema-17.0" do
      xml = Samples.xml "SAP-Schema-17.0"
      domain = described_class.new(xml, "SAP-Schema-17.0")
      expect(domain.is_sap_17_or_18?).to be true
    end

    it "returns false for SAP-Schema-19.0.0" do
      xml = Samples.xml "SAP-Schema-19.0.0"
      domain = described_class.new(xml, "SAP-Schema-19.0.0")
      expect(domain.is_sap_17_or_18?).to be false
    end

    it "returns false for SAP-Schema-16.0" do
      xml = Samples.xml("SAP-Schema-16.0", "sap")
      domain = described_class.new(xml, "SAP-Schema-16.0")
      expect(domain.is_sap_17_or_18?).to be false
    end

    it "returns false for RdSAP which contains string 'SAP'" do
      xml = Samples.xml "RdSAP-Schema-18.0"
      domain = described_class.new(xml, "RdSAP-Schema-18.0")
      expect(domain.is_sap_17_or_18?).to be false
    end

    it "returns false for SAP-Schema-NI-18.0.0" do
      xml = Samples.xml "SAP-Schema-NI-18.0.0"
      domain = described_class.new(xml, "SAP-Schema-NI-18.0.0")
      expect(domain.is_sap_17_or_18?).to be false
    end
  end
end
