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

  context "when data has line breaks and extra spaces" do
    let(:test_data) do
      [
        {
          assessment_id: "0000-0000-0000-0000-0001",
          address1: "28, Joicey Court\n",
          address2: "\n",
          comma_test_values: "a,b,c,\n           ",
          lodgement_date: "13-04-2009",
        },
        {
          assessment_id: "0000-0000-0000-0000-0002",
          comma_test_values: "1,2\r",
          address1: "88\n Station Lane",
          lodgement_date: "01-02-2020",
        },
      ]
    end

    let(:expectation) do
      [
        {
          assessment_id: "0000-0000-0000-0000-0001",
          address1: "28, Joicey Court",
          address2: "",
          comma_test_values: "a,b,c, ",
          lodgement_date: "13-04-2009",
        },
        {
          assessment_id: "0000-0000-0000-0000-0002",
          comma_test_values: "1,2",
          address1: "88 Station Lane",
          lodgement_date: "01-02-2020",
        },
      ]
    end

    it "returns an object with line breaks, carriage returns and extra spaces removed" do
      expect(helper.remove_line_breaks(test_data)).to eq(expectation)
    end
  end

  context "when data includes frozen strings or non-string objects" do
    let(:test_data) do
      [
        {
          assessment_id: "0000-0000-0000-0000-0001",
          address1: "28, Joicey Court\n".freeze,
          address2: "\n",
          address3: 4,
          comma_test_values: "a,b,c,",
          lodgement_date: "13-04-2009",
        },
        {
          assessment_id: "0000-0000-0000-0000-0002",
          comma_test_values: "1,2\r".freeze,
          address1: "88\n Station Lane",
          lodgement_date: "01-02-2020",
        },
      ]
    end

    let(:expectation) do
      [
        {
          assessment_id: "0000-0000-0000-0000-0001",
          address1: "28, Joicey Court",
          address2: "",
          address3: 4,
          comma_test_values: "a,b,c,",
          lodgement_date: "13-04-2009",
        },
        {
          assessment_id: "0000-0000-0000-0000-0002",
          comma_test_values: "1,2",
          address1: "88 Station Lane",
          lodgement_date: "01-02-2020",
        },
      ]
    end

    it "returns an object with line breaks removed" do
      expect(helper.remove_line_breaks(test_data)).to eq(expectation)
    end
  end
end
