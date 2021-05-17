describe UseCase::ExportOpenDataOptOuts do
  context "when exporting opt out data for open data communities" do
    subject { described_class.new(reporting_gateway) }
    let(:reporting_gateway) { instance_double(Gateway::ReportingGateway) }

    let(:fetch_ids_response) do
      [
        { "assessment_id" => "0000-0000-0000-0000-0000" },
        { "assessment_id" => "0000-0000-0000-0000-0001" },
      ]
    end

    let(:hashed_assessments) do
      [
        {
          assessment_id:
            "4af9d2c31cf53e72ef6f59d3f59a1bfc500ebc2b1027bc5ca47361435d988e1a",
        },
        {
          assessment_id:
            "55ce7d026c13e923d26cbfb0d6ed60734d3270ba981d629a168bb8eb2da3f8c4",
        },
      ]
    end

    before do
      allow(reporting_gateway).to receive(:fetch_opted_out_assessments)
        .and_return(fetch_ids_response)
    end

    it "returns an array of hashed assessment_ids" do
      expect(subject.execute('2020-09-18')).to eq(hashed_assessments)
    end
  end
end
