describe UseCase::SearchAddressesByStreetAndTown, :set_with_timecop do
  include RSpecRegisterApiServiceMixin

  subject(:use_case) { described_class.new }

  let!(:scheme_id) do
    add_scheme_and_get_id
  end

  describe "#execute" do
    context "when searching with a street and town" do
      subject(:use_case) { described_class.new(gateway) }

      let(:gateway) { instance_double Gateway::AddressSearchGateway }
      let(:result) do
        [Domain::Address.new(
          address_id: "UPRN-000000000001",
          line1: "1",
          line2: "SOME UNIT",
          line3: "",
          line4: "",
          town: "LONDON",
          postcode: "SW1A 2AA",
          country: %w[E],
          source: "GAZETTEER",
          existing_assessments: nil,
        )]
      end

      before do
        allow(gateway).to receive(:search_by_street_and_town).and_return result
      end

      it "passes the arguments to the gateway" do
        use_case.execute(street: "Some", town: "Sometown", address_type: "COMMERCIAL")
        expect(gateway).to have_received(:search_by_street_and_town).with("Some", "Sometown", "COMMERCIAL")
      end

      it "strips characters from the input" do
        use_case.execute(street: "1 Some Street*", town: "Whitbury:!\\")
        expect(gateway).to have_received(:search_by_street_and_town).with("1 Some Street", "Whitbury", nil)
      end

      it "return the expected data" do
        expect(use_case.execute(street: "Some", town: "LONDON", address_type: "COMMERCIAL")).to eq result
      end
    end

    context "when arguments include non token characters" do
      it "returns an error when the params are shorter than 2 after sanitising" do
        expect { use_case.execute(street: "1 Some Street", town: "W:!") }.to raise_error(
          Boundary::Json::Error,
          "Values must have minimum 2 alphanumeric characters",
        )
      end
    end

    context "when there are the same addresses in both the assessments and address base" do
      before do
        add_super_assessor(scheme_id:)
        insert_into_address_base("000005689782", "SW1 2AA", "Flat 3", "1 Some Street", "London", "E")
        domestic_assessment = Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0"
        lodge_assessment(
          assessment_body: domestic_assessment.to_xml,
          accepted_responses: [201],
          auth_data: {
            scheme_ids: [scheme_id],
          },
          ensure_uprns: false,
        )
      end

      it "returns only the address from address base not from the assessment" do
        result = use_case.execute(street: "Some", town: "London")
        expect(result.length).to eq(1)
        expect(result.first.address_id).to eq("UPRN-000005689782")
      end
    end
  end
end
