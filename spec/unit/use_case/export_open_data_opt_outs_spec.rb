describe UseCase::ExportOpenDataOptOuts do
  context "when exporting opt out data for open data communities" do
    subject { described_class.new(reporting_gateway) }
    let(:reporting_gateway) { instance_double(Gateway::ReportingGateway) }

    let(:fetch_ids_response) do
      [
        {
          "assessment_id" => "0000-0000-0000-0000-0000",
          "type_of_assessment" => "RdSAP",
          "address_line1" => "1 Some Street",
          "address_line2" => "",
          "address_line3" => "",
          "town" => "Whitbury",
          "postcode" => "A0 0AA",
          "date_registered" => "2020-05-04",
          "address_id" => "UPRN-000000000000",
        },
        {
          "assessment_id" => "0000-0000-0000-0000-0001",
          "type_of_assessment" => "RdSAP",
          "address_line1" => "2 Some Street",
          "address_line2" => "",
          "address_line3" => "",
          "town" => "Whitbury",
          "postcode" => "A0 0AA",
          "date_registered" => "2020-05-04",
          "address_id" => "UPRN-000000000000",
        },
      ]
    end

    before do
      allow(reporting_gateway).to receive(:fetch_opted_out_assessments)
        .and_return(fetch_ids_response)
    end

    it "returns an array of hashed assessment_ids" do
      expected_values = %w[
        4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a
        55ce7d026c13e923d26cbfb0d6ed60734d3270ba981d629a168bb8eb2da3f8c4
      ]
      expect(subject.execute.map { |hash| hash[:assessment_id] }).to eq(
        expected_values,
      )
    end

    it "returns the correct keys sent from the gateway columns" do
      expect(subject.execute[0].keys).to eq(
        fetch_ids_response[0].symbolize_keys.keys,
      )
    end
  end
end
