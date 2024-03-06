describe Domain::Lodgement do
  let(:subject) { described_class }
  let(:border_domain) do
    Domain::CountryLookup.new(country_codes: %i[E W])
  end

  let(:english_domain) do
    Domain::CountryLookup.new(country_codes: [:E])
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
        domain.add_country_id_to_data(country_domain: english_domain)
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
        domain.add_country_id_to_data(country_domain: english_domain)

        expect(domain.fetch_data.first[:country_id]).to eq 1
      end
    end
  end

  describe "processing RdSAP assessments" do
    context "when the address is a border between England & Wales" do
      let(:xml) { Samples.xml "RdSAP-Schema-20.0.0" }

      let(:domain) { described_class.new(xml, "RdSAP-Schema-20.0.0") }

      it "returns a 4 for england and wales" do
        domain.add_country_id_to_data(country_domain: border_domain)
        expect(domain.fetch_data.first[:country_id]).to eq 4
      end
    end

    context "when schema version greater than 20 and on a border and the xml country code is england" do
      let(:xml) { Samples.xml "RdSAP-Schema-21.0.0" }

      let(:domain) { described_class.new(xml, "RdSAP-Schema-21.0.0") }

      it "has a country_id for England" do
        domain.add_country_id_to_data(country_domain: border_domain)
        expect(domain.fetch_data.first[:country_id]).to eq 1
      end
    end

    context "when schema version greater than 20 and on a border and the xml country code is wales" do
      let(:xml) { Nokogiri.XML Samples.xml("RdSAP-Schema-21.0.0") }

      before do
        xml.at("Country-Code").children = "WLS"
      end

      it "returns a 2 for Wales " do
        domain = described_class.new(xml.to_s, "RdSAP-Schema-21.0.0")
        domain.add_country_id_to_data(country_domain: border_domain)
        expect(domain.fetch_data.first[:country_id]).to eq 2
      end
    end
  end

  describe "processing SAP assessments" do
    context "when on a border of England & Wales" do
      let(:xml) { Samples.xml "SAP-Schema-18.0.0" }

      let(:domain) { described_class.new(xml, "SAP-Schema-18.0.0") }

      it "returns a 4 for england & wales " do
        domain.add_country_id_to_data(country_domain: border_domain)
        expect(domain.fetch_data.first[:country_id]).to eq 4
      end
    end

    context "when a schema version greater than 18 on a border and the xml country code is england" do
      let(:xml) { Samples.xml "SAP-Schema-19.0.0" }

      let(:domain) { described_class.new(xml, "SAP-Schema-19.0.0") }

      it "returns a 1 for england " do
        domain.add_country_id_to_data(country_domain: border_domain)
        expect(domain.fetch_data.first[:country_id]).to eq 1
      end
    end

    context "when a schema version greater than 18 on a border and the xml country code is wales" do
      let(:xml) { Nokogiri.XML Samples.xml("SAP-Schema-19.0.0") }

      before do
        xml.at("Country-Code").children = "WLS"
      end

      it "returns a 2 for Wales " do
        domain = described_class.new(xml.to_s, "SAP-Schema-19.0.0")
        domain.add_country_id_to_data(country_domain: border_domain)
        expect(domain.fetch_data.first[:country_id]).to eq 2
      end
    end
  end

  describe "processing CEPC" do
    let(:xml) { Samples.xml "CEPC-8.0.0", "cepc+rr" }

    let(:domain) { described_class.new(xml, "CEPC-8.0.0") }

    it "returns a 1 for england " do
      domain.add_country_id_to_data(country_domain: english_domain)
      expect(domain.fetch_data.first[:country_id]).to eq 1
    end
  end
end
