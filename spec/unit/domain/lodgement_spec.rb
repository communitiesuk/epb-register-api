describe Domain::Lodgement do
  let(:subject) { described_class }
  let(:border_domain) do
    Domain::CountryLookup.new(country_codes: %i[E W])
  end

  let(:english_domain) do
    Domain::CountryLookup.new(country_codes: [:E])
  end

  let!(:rdsap_20) {
    Samples.xml "RdSAP-Schema-20.0.0"
  }

  let!(:rdsap_21) {
    Samples.xml "RdSAP-Schema-21.0.0"
  }

  let!(:cepc) {
    Samples.xml "CEPC-8.0.0", "dec-rr"
  }

  describe "#fetch_data" do
    context "when an RdSAP is passed" do

      let(:domain) { described_class.new(rdsap_20, "RdSAP-Schema-20.0.0") }

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

  describe "#country_code" do
    it "returns the country code from an RdSAP" do
      domain = described_class.new(rdsap_20, "RdSAP-Schema-20.0.0")
      expect(domain.country_code).to eq("EAW")
    end

    it "returns the country code from an RdSAP 21.0.0" do

      domain = described_class.new(rdsap_21, "RdSAP-Schema-21.0.0")
      expect(domain.country_code).to eq("ENG")
    end

    it "returns the country code from a SAP 19.1.0" do
      xml = Samples.xml "SAP-Schema-19.1.0"
      domain = described_class.new(xml, "SAP-Schema-19.1.0")
      expect(domain.country_code).to eq("ENG")
    end

  end


  describe "#schema_version" do
    it "returns decimal of the RdSAP schema version" do

      domain = described_class.new(rdsap_20, "RdSAP-Schema-20.0.0")
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
      expect(domain.is_new_rdsap?).to eq true
    end

    it "returns false for RdSAP-Schema-20.0.0" do

      domain = described_class.new(rdsap_20, "RdSAP-Schema-20.0.0")
      expect(domain.is_new_rdsap?).to eq false
    end

    it "returns false for CPEC" do
      domain = described_class.new(cepc, "CEPC-8.0.0")
      expect(domain.is_new_rdsap?).to eq false
    end

  end

end
