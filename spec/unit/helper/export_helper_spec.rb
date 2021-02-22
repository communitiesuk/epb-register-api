describe Helper::ExportHelper do
  let(:helper) { described_class }

  context "when given data from the domestic recommendations open data export use-case" do
    let(:domestic_recommendations_data) do
      [
        {
          recommendations: [
            {
              assessment_id: "0000-0000-0000-0000-0000",
              improvement_code: "5",
              improvement_description: nil,
              improvement_summary: nil,
              indicative_cost: "£100 - £350",
              sequence: 1,
            },
            {
              assessment_id: "0000-0000-0000-0000-0000",
              improvement_code: "1",
              improvement_description: nil,
              improvement_summary: nil,
              indicative_cost: "2000",
              sequence: 2,
            },
          ],
        },
        {
          recommendations: [
            {
              assessment_id: "0000-0000-0000-0000-1000",
              improvement_code: "5",
              improvement_description: nil,
              improvement_summary: nil,
              indicative_cost: "£100 - £350",
              sequence: 1,
            },
            {
              assessment_id: "0000-0000-0000-0000-1000",
              improvement_code: "1",
              improvement_description: nil,
              improvement_summary: nil,
              indicative_cost: "2000",
              sequence: 2,
            },
          ],
        },
      ]
    end

    it "produces a flat array of individual recommendation hashes" do
      result =
        helper.flatten_domestic_rr_response(domestic_recommendations_data)
      expect(result).to eq [
        {
          assessment_id: "0000-0000-0000-0000-0000",
          improvement_code: "5",
          improvement_description: nil,
          improvement_summary: nil,
          indicative_cost: "£100 - £350",
          sequence: 1,
        },
        {
          assessment_id: "0000-0000-0000-0000-0000",
          improvement_code: "1",
          improvement_description: nil,
          improvement_summary: nil,
          indicative_cost: "2000",
          sequence: 2,
        },
        {
          assessment_id: "0000-0000-0000-0000-1000",
          improvement_code: "5",
          improvement_description: nil,
          improvement_summary: nil,
          indicative_cost: "£100 - £350",
          sequence: 1,
        },
        {
          assessment_id: "0000-0000-0000-0000-1000",
          improvement_code: "1",
          improvement_description: nil,
          improvement_summary: nil,
          indicative_cost: "2000",
          sequence: 2,
        },
      ]
    end
  end

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
          address1: "88, Station Lane",
          comma_test_values: "1,2",
          lodgement_date: "01-02-2020",
        },
      ]
    end

    it "returns a csv that matches the expectation and is formatted correctly" do
      expect(expectation).to eq(helper.to_csv(test_data))
    end
  end

  context "when mapping between csv header to fixture header values" do
    let(:report_keys) do
      %w[
        assessment_id
        improvement_code
        improvement_description
        improvement_summary
        indicative_cost
        sequence
      ]
    end
    let(:expectation) do
      %w[
        ASSESSMENT_ID
        IMPROVEMENT_ITEM
        INDICATIVE_COST
        IMPROVEMENT_SUMMARY_TEXT
        IMPROVEMENT_DESCR_TEXT
        IMPROVEMENT_ID
      ]
    end

    let(:convert_method) { helper.convert_header_values(report_keys) }

    it "maps the expected column headers from the report" do
      expect(convert_method).to match_array(expectation)
    end

    context "when mapping between csv header to fixture header values" do
      let(:report_keys) do
        %w[
          assessment_id
          improvement_code
          improvement_description
          improvement_summary
          indicative_cost
          sequence
        ]
      end
      let(:expectation) do
        %w[
          ASSESSMENT_ID
          IMPROVEMENT_ITEM
          INDICATIVE_COST
          IMPROVEMENT_SUMMARY_TEXT
          IMPROVEMENT_DESCR_TEXT
          IMPROVEMENT_ID
        ]
      end
      let(:convert_method) { helper.convert_header_values(report_keys) }
      it "maps the expected column headers from the report" do
        expect(convert_method).to match_array(expectation)
      end
    end
  end
end
