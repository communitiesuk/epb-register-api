describe UseCase::FindDomesticEpcByAddress do
  subject(:use_case) { described_class.new(gateway:) }

  let(:gateway) { instance_double(Gateway::DomesticEpcSearchGateway) }

  it "can load the class and pass the gateway" do
    expect { use_case }.not_to raise_error
  end

  describe "#execute" do
    let(:building_identifier) { "42" }

    let(:postcode) { "AB1 2CD" }

    let(:results) do
      [
        Domain::DomesticEpcSearchResult.new(assessment_id: "0000-0000-0000-0000-9999",
                                            address_line1: "1 Your Street", address_line2: "", address_line3: "", address_line4: "", postcode: "AB1 2CD", town: "London"),
      ]
    end

    let(:expected_details) do
      { assessments: results }
    end

    context "when fetching address where one relevant assessment exists" do
      before do
        allow(gateway).to receive(:fetch_by_address)
                                .with(postcode:, building_identifier:)
                                .and_return(results)
      end

      it "returns the assessment result hash" do
        expect(use_case.execute(postcode:, building_identifier:)).to eq expected_details
      end
    end

    context "when fetching address where more than one relevant assessment exists" do
      let(:extra_address)  do
        Domain::DomesticEpcSearchResult.new(assessment_id: "0000-0000-0000-0000-1234",
                                            address_line1: "1 My Street", address_line2: "", address_line3: "", address_line4: "", postcode: "AB1 2CD", town: "London")
      end

      let(:multiple_results) do
        results << extra_address
      end

      let(:expected_multiple_details) do
        { assessments: results << extra_address }
      end

      before do
        allow(gateway).to receive(:fetch_by_address)
                            .with(postcode:, building_identifier:)
                            .and_return(multiple_results)
      end

      it "returns the assessment result hash with both elements" do
        expect(use_case.execute(postcode:, building_identifier:)).to eq expected_multiple_details
      end
    end
  end
end
