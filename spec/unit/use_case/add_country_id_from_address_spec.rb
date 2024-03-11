describe UseCase::AddCountryIdFromAddress do
  subject(:use_case) { described_class.new gateway }

  let(:border_domain) do
    Domain::CountryLookup.new(country_codes: %i[E W])
  end

  let(:english_domain) do
    Domain::CountryLookup.new(country_codes: [:E])
  end

  let(:gateway) do
    instance_double Gateway::CountryGateway
  end

  let(:countries) do
    [{ country_code: "ENG", address_base_country_code: "[\"E\"]", country_id: 1, country_name: "England" },
     { country_code: "EAW", address_base_country_code: "[\"E\", \"W\"]", country_id: 4, country_name: "England and Wales" },
     { country_code: "WLS", address_base_country_code:  "[\"W\"]", country_id: 2, country_name: "Wales" },
     { country_code: "NIR", address_base_country_code:  "[\"N\"]", country_id: 3, country_name: "Northern Ireland" },
     { country_code: "NR", address_base_country_code: "", country_id: 5, country_name: "Not Recorded" },
     { country_code: "UKN", address_base_country_code: "", country_id: 6, country_name: "Unknown" }]
  end

  before do
    allow(gateway).to receive(:fetch_countries).and_return countries
  end

  context "when the class is instantiated" do
    before do
      described_class.new gateway
    end

    it "extracts the counties from the gateway" do
      expect(gateway).to have_received(:fetch_countries)
    end
  end

  describe "#execute" do
    let(:xml) { Samples.xml "RdSAP-Schema-20.0.0" }

    it "does not raise an error" do
      country_domain = Domain::CountryLookup.new(country_codes: [:E])
      lodgement_domain = Domain::Lodgement.new(xml, "RdSAP-Schema-21.0.0")
      expect { use_case.execute(country_domain:, lodgement_domain:) }.not_to raise_error
    end

    context "when passing an RdSAP" do
      let(:xml) { Samples.xml "RdSAP-Schema-20.0.0" }

      let(:lodgement_domain) { Domain::Lodgement.new(xml, "RdSAP-Schema-20.0.0") }

      it "adds the id for England to the lodgement" do
        country_domain = Domain::CountryLookup.new(country_codes: [:E])
        use_case.execute(country_domain:, lodgement_domain:)
        expect(lodgement_domain.fetch_data.first[:country_id]).to eq 1
      end

      context "when schema version greater than 20 and on a border and the xml country code is england" do
        let(:xml) { Samples.xml "RdSAP-Schema-21.0.0" }

        let(:lodgement_domain) { Domain::Lodgement.new(xml, "RdSAP-Schema-21.0.0") }

        it "has a country_id for England" do
          use_case.execute(country_domain: border_domain, lodgement_domain:)
          expect(lodgement_domain.fetch_data.first[:country_id]).to eq 1
        end
      end

      context "when schema version greater than 20 and on a border and the xml country code is wales" do
        let(:xml) { Nokogiri.XML Samples.xml("RdSAP-Schema-21.0.0") }

        before do
          xml.at("Country-Code").children = "WLS"
        end

        it "returns a 2 for Wales " do
          lodgement_domain = Domain::Lodgement.new(xml.to_s, "RdSAP-Schema-21.0.0")
          use_case.execute(country_domain: border_domain, lodgement_domain:)
          expect(lodgement_domain.fetch_data.first[:country_id]).to eq 2
        end
      end

      context "when it is a northern ireland epc" do
        let(:xml) { Samples.xml("RdSAP-Schema-NI-20.0.0") }

        let(:lodgement_domain) { Domain::Lodgement.new(xml, "RdSAP-Schema-NI-20.0.0") }
        let(:country_domain) { Domain::CountryLookup.new(country_codes: [:N]) }

        it "has a country_id for NI" do
          use_case.execute(country_domain:, lodgement_domain:)
          expect(lodgement_domain.fetch_data.first[:country_id]).to eq 3
        end
      end
    end

    context "when passing a SAP" do
      context "when on a border of England & Wales" do
        let(:xml) { Samples.xml "SAP-Schema-18.0.0" }

        let(:lodgement_domain) { Domain::Lodgement.new(xml, "SAP-Schema-18.0.0") }

        it "returns a 4 for england & wales " do
          use_case.execute(country_domain: border_domain, lodgement_domain:)
          expect(lodgement_domain.fetch_data.first[:country_id]).to eq 4
        end
      end

      context "when a schema version greater than 18 on a border and the xml country code is england" do
        let(:xml) { Samples.xml "SAP-Schema-19.1.0" }

        let(:lodgement_domain) { Domain::Lodgement.new(xml, "SAP-Schema-19.1.0") }

        it "returns a 1 for england " do
          use_case.execute(country_domain: border_domain, lodgement_domain:)
          expect(lodgement_domain.fetch_data.first[:country_id]).to eq 1
        end
      end

      context "when the country code is null" do
        let(:xml) { Nokogiri.XML Samples.xml("SAP-Schema-19.0.0") }
        let(:lodgement_domain) { Domain::Lodgement.new(xml.to_s, "SAP-Schema-19.0.0") }
        let(:country_domain) { Domain::CountryLookup.new(country_codes: []) }

        before do
          xml.at("Country-Code").children = "NR"
        end

        it "falls back to using the value from the xml " do
          use_case.execute(country_domain:, lodgement_domain:)
          expect(lodgement_domain.fetch_data.first[:country_id]).to eq 5
        end
      end

      context "when the xml country code is null and the country code is null" do
        let(:xml) { Nokogiri.XML Samples.xml("SAP-Schema-17.0") }
        let(:lodgement_domain) { Domain::Lodgement.new(xml.to_s, "SAP-Schema-17.0") }
        let(:country_domain) { Domain::CountryLookup.new(country_codes: []) }

        it "falls back to using the value from the xml " do
          use_case.execute(country_domain:, lodgement_domain:)
          expect(lodgement_domain.fetch_data.first[:country_id]).to eq 6
        end
      end
    end

    context "when passing a CEPC Dual lodgement" do
      let(:xml) { Samples.xml "CEPC-8.0.0", "cepc+rr" }

      let(:lodgement_domain) { Domain::Lodgement.new(xml, "CEPC-8.0.0") }

      it "returns a 1 for england " do
        use_case.execute(country_domain: english_domain, lodgement_domain:)
        expect(lodgement_domain.fetch_data.first[:country_id]).to eq 1
      end
    end

    context "when passing a CEPC" do
      let(:xml) { Samples.xml "CEPC-8.0.0", "cepc-rr" }

      let(:lodgement_domain) { Domain::Lodgement.new(xml, "CEPC-8.0.0") }

      it "returns a 1 for england " do
        use_case.execute(country_domain: english_domain, lodgement_domain:)
        expect(lodgement_domain.fetch_data.first[:country_id]).to eq 1
      end
    end

    context "when passing a CEPC with no found address" do
      let(:xml) { Samples.xml "CEPC-8.0.0", "cepc-rr" }

      let(:lodgement_domain) { Domain::Lodgement.new(xml, "CEPC-8.0.0") }

      it "returns a 6 for not found " do
        use_case.execute(country_domain: nil, lodgement_domain:)
        expect(lodgement_domain.fetch_data.first[:country_id]).to eq 6
      end
    end

    context "when passing a DEC" do
      let(:xml) { Samples.xml "CEPC-8.0.0", "dec-rr" }

      let(:lodgement_domain) { Domain::Lodgement.new(xml, "CEPC-8.0.0") }

      it "returns a 1 for england " do
        use_case.execute(country_domain: english_domain, lodgement_domain:)
        expect(lodgement_domain.fetch_data.first[:country_id]).to eq 1
      end
    end

    context "when no value for unknown in the table" do
      let(:xml) { Samples.xml "CEPC-8.0.0", "dec-rr" }

      let(:lodgement_domain) { Domain::Lodgement.new(xml, "CEPC-8.0.0") }

      it "does not error and returns a nil " do
        allow(gateway).to receive(:fetch_countries).and_return [{ country_code: "ENG", address_base_country_code: "[\"E\"]", country_id: 1, country_name: "England" }]

        use_case.execute(country_domain: nil, lodgement_domain:)
        expect(lodgement_domain.fetch_data.first[:country_id]).to be_nil
      end
    end
  end
end
