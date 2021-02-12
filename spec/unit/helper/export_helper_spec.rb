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
end
