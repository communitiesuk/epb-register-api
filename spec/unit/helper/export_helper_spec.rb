describe Helper::ExportHelper do
  let(:helper) { described_class }

  context "when turning exported data into a csv" do
    let(:expectation) do
      csv = <<~CSV
        ASSESSMENT_ID,ADDRESS1,COMMA_TEST_VALUES,LODGEMENT_DATE
        0000-0000-0000-0000-0001,"28, Joicey Court","a,b,c,",13-04-2009
        0000-0000-0000-0000-0002,"88, Station Lane","1,2",01-02-2020
      CSV
      csv
    end

    let(:test_data) do
      [
        {
          assessment_id: "0000-0000-0000-0000-0001",
          address1: "28, Joicey Court",
          comma_test_values: "a,b,c,",
          lodgement_date: "13-04-2009",
        },
        {
          assessment_id: "0000-0000-0000-0000-0002",
          comma_test_values: "1,2",
          address1: "88, Station Lane",
          lodgement_date: "01-02-2020",
        },
      ]
    end

    it "returns a csv that matches the expectation and is formatted correctly" do
      expect(expectation).to eq(helper.to_csv(test_data))
    end
  end
end
