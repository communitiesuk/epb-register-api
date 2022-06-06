describe Helper::AddressSearchHelper do
  describe "#where_postcode_clause" do
    it "returns a string of a sql expression for filtering by postcode" do
      expect(described_class.where_postcode_clause).to be_a(String)
      expect(described_class.where_postcode_clause.to_s.strip).to start_with("AND a.postcode ")
    end
  end

  describe "#where_number_clause" do
    it "returns a string of a sql expression for filtering by building number" do
      expect(described_class.where_number_clause).to be_a(String)
      expect(described_class.where_number_clause.to_s.strip).to start_with("AND\n        (\n          a.address_line1")
    end
  end

  describe "#clean_building_identifier" do
    it "returns a string of a with special chars removed", aggregate_failures: true do
      expect(described_class.clean_building_identifier("1")).to eq("1")
      expect(described_class.clean_building_identifier("1() Some Street")).to eq("1 Some Street")
      expect(described_class.clean_building_identifier("1: Some Street")).to eq("1 Some Street")
    end
  end

  describe "#where_postcode_and_name_clause" do
    it "returns a string of a sql expression for filtering by postcode and building name" do
      expect(described_class.where_name_clause.to_s.strip).to eq "AND (a.address_line1 ILIKE $2 OR a.address_line2 ILIKE $2)"
    end
  end

  describe "#string_attribute" do
    it "returns a Active record query attribute", aggregate_failures: true do
      result = described_class.string_attribute("postcode", "A1 2SS")
      expect(result).to be_a(ActiveRecord::Relation::QueryAttribute)
      expect(result.name).to eq("postcode")
      expect(result.value).to eq("A1 2SS")
    end
  end

  describe "#bind_postcode_and_number", aggregate_failures: true do
    it "returns a array of string attributes for regex address searches", aggregate_failures: true do
      result = described_class.bind_postcode_and_number("A1 2SS", "12A Some Street")
      expect(result).to be_an(Array)
      expect(result.length).to eq(5)
      expect(result.first).to be_a(ActiveRecord::Relation::QueryAttribute)
      expect(result.last).to be_a(ActiveRecord::Relation::QueryAttribute)
      expect(result.first.name).to eq "postcode"
      expect(result[1].value).to eq("\\D+12A Some Street\\D+")
      expect(result[2].value).to eq("^12A Some Street\\D+")
      expect(result[3].value).to eq("\\D+12A Some Street$")
      expect(result[4].value).to eq("12A Some Street")
    end
  end

  describe "#bind_postcode_and_name", aggregate_failures: true do
    it "returns a array of string attributes for regex address searches", aggregate_failures: true do
      result = described_class.bind_postcode_and_name("A1 2SS", "Some Name")
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result.first).to be_a(ActiveRecord::Relation::QueryAttribute)
      expect(result.last).to be_a(ActiveRecord::Relation::QueryAttribute)
      expect(result.first.name).to eq "postcode"
      expect(result[0].value).to eq("A1 2SS")
      expect(result[1].value).to eq("%Some Name%")
    end
  end
end
