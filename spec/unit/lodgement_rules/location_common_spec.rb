shared_context "when testing common location lodgement rules" do
  def assert_errors(doc, xml_updates, country_lookup, error, message)
    xml_doc = doc[:xml_doc]
    xml_updates.each do |key, value|
      xml_doc.at(key)&.children = value
    end
    wrapper = ViewModel::Factory.new.create(xml_doc.to_xml, doc[:schema_name])
    adapter = wrapper.get_view_model
    if error.nil?
      (expect {
        described_class
          .new
          .validate(schema_name: doc[:schema_name],
                    xml_adaptor: adapter,
                    country_lookup: Domain::CountryLookup.new(country_codes: country_lookup))
      }.not_to raise_error)
    else
      (expect {
        described_class
          .new
          .validate(schema_name: doc[:schema_name],
                    xml_adaptor: adapter,
                    country_lookup: Domain::CountryLookup.new(country_codes: country_lookup))
      }
          .to raise_error(error, message))
    end
  end
end

describe LodgementRules::LocationCommon do
  include_context "when testing common location lodgement rules"

  describe "#validate" do
    context "when schema is not Scottish" do
      let!(:domestic_under_test) do
        [{
          xml_doc:
             Nokogiri.XML(Samples.xml("RdSAP-Schema-21.0.0", "epc")).remove_namespaces!,
          schema_name: "RdSAP-Schema-21.0.0",
        },
         {
           xml_doc:
             Nokogiri.XML(Samples.xml("SAP-Schema-19.2.0", "epc")).remove_namespaces!,
           schema_name: "SAP-Schema-19.2.0",
         },
         {
           xml_doc:
             Nokogiri.XML(Samples.xml("RdSAP-Schema-NI-21.0.1", "epc")).remove_namespaces!,
           schema_name: "RdSAP-Schema-NI-21.0.1",
         },
         {
           xml_doc:
             Nokogiri.XML(Samples.xml("SAP-Schema-NI-18.0.0", "epc")).remove_namespaces!,
           schema_name: "SAP-Schema-NI-18.0.0",
         }]
      end
      let!(:non_domestic_under_test) do
        [
          {
            xml_doc:
              Nokogiri.XML(Samples.xml("CEPC-8.0.0", "cepc")).remove_namespaces!,
            schema_name: "CEPC-8.0.0",
          },
          {
            xml_doc:
              Nokogiri.XML(Samples.xml("CEPC-NI-8.0.0", "cepc")).remove_namespaces!,
            schema_name: "CEPC-NI-8.0.0",
          },
          {
            xml_doc:
              Nokogiri.XML(Samples.xml("CEPC-8.0.0", "dec")).remove_namespaces!,
            schema_name: "CEPC-8.0.0",
          },
          {
            xml_doc:
              Nokogiri.XML(Samples.xml("CEPC-NI-8.0.0", "dec")).remove_namespaces!,
            schema_name: "CEPC-NI-8.0.0",
          },
        ]
      end
      let!(:docs_under_test) do
        domestic_under_test + non_domestic_under_test
      end

      context "when checking which country the address is in" do
        let(:error) do
          Boundary::InvalidLocation
        end
        let(:message) do
          "Property address must be in England, Wales, or Northern Ireland"
        end

        it "returns no error if the country lookup is England" do
          docs_under_test.each do |doc|
            assert_errors(doc, [], %w[E], nil, nil)
          end
        end

        it "returns no error if the country lookup is Wales" do
          docs_under_test.each do |doc|
            assert_errors(doc, [], %w[W], nil, nil)
          end
        end

        it "returns no error if the country lookup is Northern Ireland" do
          docs_under_test.each do |doc|
            assert_errors(doc, [], %w[N], nil, nil)
          end
        end

        it "returns no error if the country lookup is on the Scotland/England border" do
          docs_under_test.each do |doc|
            assert_errors(doc, [], %w[S E], nil, nil)
          end
        end

        it "returns no error if the country lookup is on the Wales/England border" do
          docs_under_test.each do |doc|
            assert_errors(doc, [], %w[W E], nil, nil)
          end
        end

        it "returns the error if the country lookup is Scotland" do
          docs_under_test.each do |doc|
            assert_errors(doc, [], %w[S], error, message)
          end
        end

        it "returns the error if the country lookup is Jersey or Guernsey" do
          docs_under_test.each do |doc|
            assert_errors(doc, [], %w[L], error, message)
          end
        end

        it "returns the error if the country lookup is Isle of Man" do
          docs_under_test.each do |doc|
            assert_errors(doc, [], %w[M], error, message)
          end
        end
      end

      context "when checking the country code" do
        let(:error) do
          Boundary::InvalidLocation
        end
        let(:message) do
          "Country code must not be SCT"
        end

        it "returns the error if the country code is Scotland" do
          domestic_under_test.each do |doc|
            assert_errors(doc, [%w[Country-Code SCT]], %w[E], error, message)
          end
        end

        it "returns no error if the country code is England" do
          domestic_under_test.each do |doc|
            assert_errors(doc, [%w[Country-Code ENG]], %w[E], nil, message)
          end
        end
      end

      context "when the postcode is non geographic" do
        let(:error) do
          Boundary::InvalidLocation
        end
        let(:message) do
          "Non-geographic and overseas postcodes are not allowed"
        end

        [
          "BF1 2AU",
          "BX8 0HB",
          "XM4 5HQ",
          "XX40 4AA",
          "GX11 1AA",
        ].each do |postcode|
          it "returns an error if the address is #{postcode}" do
            domestic_under_test.each do |doc|
              assert_errors(doc, [["Address/Postcode", postcode]], %w[E], error, message)
            end
          end
        end
      end
    end

    context "when schema is Scottish" do
      let!(:domestic_under_test) do
        [{
          xml_doc:
            Nokogiri.XML(Samples.xml("RdSAP-Schema-S-22.0.0", "epc")).remove_namespaces!,
          schema_name: "RdSAP-Schema-S-22.0.0",
        },
         {
           xml_doc:
             Nokogiri.XML(Samples.xml("SAP-Schema-S-20.0.0", "epc")).remove_namespaces!,
           schema_name: "SAP-Schema-S-20.0.0",
         }]
      end
      let!(:non_domestic_under_test) do
        [
          {
            xml_doc:
              Nokogiri.XML(Samples.xml("CEPC-S-8.0.0", "cepc")).remove_namespaces!,
            schema_name: "CEPC-S-8.0.0",
          },
          {
            xml_doc:
              Nokogiri.XML(Samples.xml("DECAR-S-8.0.0", "dec")).remove_namespaces!,
            schema_name: "DECAR-S-8.0.0",
          },
          {
            xml_doc:
              Nokogiri.XML(Samples.xml("CS63-S-8.0.0", "cs63")).remove_namespaces!,
            schema_name: "CS63-S-8.0.0",
          },
        ]
      end
      let!(:docs_under_test) do
        domestic_under_test + non_domestic_under_test
      end

      context "when checking which country the address is in" do
        let(:error) do
          Boundary::InvalidLocation
        end
        let(:message) do
          "Property address must be in Scotland"
        end

        it "returns no error if the country lookup is Scotland" do
          docs_under_test.each do |doc|
            assert_errors(doc, [], %w[S], nil, nil)
          end
        end

        it "returns no error if the country lookup is on the Scotland/England border" do
          docs_under_test.each do |doc|
            assert_errors(doc, [], %w[S E], nil, nil)
          end
        end

        it "returns the error if the country lookup is England" do
          docs_under_test.each do |doc|
            assert_errors(doc, [], %w[E], error, message)
          end
        end

        it "returns the error if the country lookup is Wales" do
          docs_under_test.each do |doc|
            assert_errors(doc, [], %w[W], error, message)
          end
        end

        it "returns the error if the country lookup is Northern Ireland" do
          docs_under_test.each do |doc|
            assert_errors(doc, [], %w[N], error, message)
          end
        end

        it "returns the error if the country lookup is Jersey or Guernsey" do
          docs_under_test.each do |doc|
            assert_errors(doc, [], %w[L], error, message)
          end
        end

        it "returns the error if the country lookup is Isle of Man" do
          docs_under_test.each do |doc|
            assert_errors(doc, [], %w[M], error, message)
          end
        end
      end

      context "when checking the country code" do
        let(:error) do
          Boundary::InvalidLocation
        end
        let(:message) do
          "Country code must be SCT"
        end

        it "returns no error if the country code is Scotland" do
          domestic_under_test.each do |doc|
            assert_errors(doc, [%w[Country-Code SCT]], %w[S], nil, message)
          end
        end

        it "returns the error if the country code is England" do
          domestic_under_test.each do |doc|
            assert_errors(doc, [%w[Country-Code ENG]], %w[S], error, message)
          end
        end

        it "returns the error if the country code is Wales" do
          domestic_under_test.each do |doc|
            assert_errors(doc, [%w[Country-Code WLS]], %w[S], error, message)
          end
        end

        it "returns the error if the country code is England and Wales" do
          domestic_under_test.each do |doc|
            assert_errors(doc, [%w[Country-Code EAW]], %w[S], error, message)
          end
        end

        it "returns the error if the country code is Northern Ireland" do
          domestic_under_test.each do |doc|
            assert_errors(doc, [%w[Country-Code NI]], %w[S], error, message)
          end
        end
      end

      context "when the postcode is non geographic" do
        let(:error) do
          Boundary::InvalidLocation
        end
        let(:message) do
          "Non-geographic and overseas postcodes are not allowed"
        end

        [
          "BF1 2AU",
          "BX8 0HB",
          "XM4 5HQ",
          "XX40 4AA",
          "GX11 1AA",
        ].each do |postcode|
          it "returns an error if the address is #{postcode} for domestic schemas" do
            domestic_under_test.each do |doc|
              assert_errors(doc, [["Address/Postcode", postcode]], %w[S], error, message)
            end
          end

          it "returns an error if the address is #{postcode} for non-domestic schemas" do
            non_domestic_under_test.each do |doc|
              assert_errors(doc, [["Postcode", postcode]], %w[S], error, message)
            end
          end
        end
      end
    end
  end
end
