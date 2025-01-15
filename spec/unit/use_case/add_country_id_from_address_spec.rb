describe UseCase::AddCountryIdFromAddress do
  subject(:use_case) { described_class.new gateway }

  let(:border_domain) do
    Domain::CountryLookup.new(country_codes: %i[E W])
  end

  let(:english_domain) do
    Domain::CountryLookup.new(country_codes: [:E])
  end

  let(:scotland_domain) do
    Domain::CountryLookup.new(country_codes: [:S])
  end

  let(:gateway) do
    instance_double Gateway::CountryGateway
  end

  let(:countries) do
    [{ country_id: 1, country_code: "ENG", address_base_country_code: "[\"E\"]", country_name: "England" },
     { country_id: 2, country_code: "WLS", address_base_country_code:  "[\"W\"]", country_name: "Wales" },
     { country_id: 3, country_code: "NIR", address_base_country_code:  "[\"N\"]", country_name: "Northern Ireland" },
     { country_id: 4, country_code: "EAW", address_base_country_code: "[\"E\", \"W\"]", country_name: "England and Wales" },
     { country_id: 5, country_code: "NR", address_base_country_code: "", country_name: "Not Recorded" },
     { country_id: 6, country_code: "UKN", address_base_country_code: "", country_name: "Unknown" },
     { country_id: 7, country_code: "SCT", address_base_country_code: "[\"S\"]", country_name: "Scotland" }]
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

    context "when passing an RdSAP" do
      context "when the schema is 20 or below" do
        let(:xml) { Samples.xml "RdSAP-Schema-20.0.0" }

        let(:lodgement_domain) { Domain::Lodgement.new(xml, "RdSAP-Schema-20.0.0") }

        it "uses the country domain (E) as the country code" do
          use_case.execute(country_domain: english_domain, lodgement_domain:)
          expect(lodgement_domain.fetch_data.first[:country_id]).to eq 1
        end
      end

      context "when the schema is greater than 20" do
        context "when it is in England and the XML country is England" do
          let(:xml) { Samples.xml "RdSAP-Schema-21.0.0" }
          let(:lodgement_domain) { Domain::Lodgement.new(xml, "RdSAP-Schema-21.0.0") }

          it "uses the XML country code (ENG) as the country code" do
            use_case.execute(country_domain: english_domain, lodgement_domain:)
            expect(lodgement_domain.fetch_data.first[:country_id]).to eq 1
          end
        end

        context "when it is on the border and the XML country is England" do
          let(:xml) { Samples.xml "RdSAP-Schema-21.0.0" }
          let(:lodgement_domain) { Domain::Lodgement.new(xml, "RdSAP-Schema-21.0.0") }

          it "uses the XML country code (ENG) as the country code" do
            use_case.execute(country_domain: border_domain, lodgement_domain:)
            expect(lodgement_domain.fetch_data.first[:country_id]).to eq 1
          end
        end
      end
    end

    context "when passing a SAP" do
      context "when on the border" do
        context "when the schema version greater than 18" do
          let(:xml) { Samples.xml "SAP-Schema-19.1.0" }

          let(:lodgement_domain) { Domain::Lodgement.new(xml, "SAP-Schema-19.1.0") }

          it "uses XML country code (ENG) as the country code" do
            use_case.execute(country_domain: border_domain, lodgement_domain:)
            expect(lodgement_domain.fetch_data.first[:country_id]).to eq 1
          end
        end

        context "when the schema is below 17" do
          let(:xml) { Nokogiri.XML Samples.xml("SAP-Schema-16.0", "sap") }

          it "uses the country domain (EAW) as the country code" do
            lodgement_domain = Domain::Lodgement.new(xml.to_s, "SAP-Schema-16.0")
            use_case.execute(country_domain: border_domain, lodgement_domain:)
            expect(lodgement_domain.fetch_data.first[:country_id]).to eq 4
          end
        end
      end

      context "when on the border of England & Wales" do
        context "when the schema is 17 or 18" do
          context "when the assessor has lodged 'EAW'" do
            let(:xml) { Samples.xml "SAP-Schema-18.0.0" }
            let(:lodgement_domain) { Domain::Lodgement.new(xml, "SAP-Schema-18.0.0") }

            it "uses the country domain (EAW) as the country code" do
              use_case.execute(country_domain: border_domain, lodgement_domain:)
              expect(lodgement_domain.fetch_data.first[:country_id]).to eq 4
            end
          end

          context "when the assessor has lodged a specific country" do
            let(:xml) { Nokogiri.XML Samples.xml("SAP-Schema-17.0") }

            before do
              xml.at("Report-Header").add_child("<Country-Code/>")
              xml.at("Country-Code").children = "WLS"
            end

            it "uses the XML country code (WLS) as the country code" do
              lodgement_domain = Domain::Lodgement.new(xml.to_s, "SAP-Schema-17.0")
              use_case.execute(country_domain: border_domain, lodgement_domain:)
              expect(lodgement_domain.fetch_data.first[:country_id]).to eq 2
            end
          end
        end
      end

      context "when in Scotland but the XML is lodged as England" do
        let(:xml) { Nokogiri.XML Samples.xml("SAP-Schema-18.0.0") }

        before do
          xml.at("Report-Header").add_child("<Country-Code/>")
          xml.at("Country-Code").children = "ENG"
        end

        it "uses the country domain (S) as the country code" do
          lodgement_domain = Domain::Lodgement.new(xml.to_s, "SAP-Schema-18.0.0")
          use_case.execute(country_domain: scotland_domain, lodgement_domain:)
          expect(lodgement_domain.fetch_data.first[:country_id]).to eq 7
        end
      end

      context "when the country code is null" do
        let(:xml) { Nokogiri.XML Samples.xml("SAP-Schema-19.0.0") }
        let(:lodgement_domain) { Domain::Lodgement.new(xml.to_s, "SAP-Schema-19.0.0") }
        let(:country_domain) { Domain::CountryLookup.new(country_codes: []) }

        before do
          xml.at("Country-Code").children = "NR"
        end

        it "falls back to using the value from the XML (NR)" do
          use_case.execute(country_domain:, lodgement_domain:)
          expect(lodgement_domain.fetch_data.first[:country_id]).to eq 5
        end
      end
    end

    context "when passing a CEPC dual lodgement" do
      let(:xml) { Samples.xml "CEPC-8.0.0", "cepc+rr" }

      let(:lodgement_domain) { Domain::Lodgement.new(xml, "CEPC-8.0.0") }

      it "uses country domain (ENG) as the country code" do
        use_case.execute(country_domain: english_domain, lodgement_domain:)
        expect(lodgement_domain.fetch_data.first[:country_id]).to eq 1
      end
    end

    context "when passing a CEPC with no country domain" do
      let(:xml) { Samples.xml "CEPC-8.0.0", "cepc-rr" }

      let(:lodgement_domain) { Domain::Lodgement.new(xml, "CEPC-8.0.0") }

      it "sets the country id for Unknown country" do
        use_case.execute(country_domain: nil, lodgement_domain:)
        expect(lodgement_domain.fetch_data.first[:country_id]).to eq 6
      end
    end

    context "when passing a DEC" do
      let(:xml) { Samples.xml "CEPC-8.0.0", "dec-rr" }

      let(:lodgement_domain) { Domain::Lodgement.new(xml, "CEPC-8.0.0") }

      it "returns a 1 for England" do
        use_case.execute(country_domain: english_domain, lodgement_domain:)
        expect(lodgement_domain.fetch_data.first[:country_id]).to eq 1
      end
    end
  end
end
