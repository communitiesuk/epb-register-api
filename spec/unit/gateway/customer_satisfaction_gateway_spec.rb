describe Gateway::CustomerSatisfactionGateway do
  subject(:gateway) { described_class.new }

  describe "#upsert" do
    context "when inserting a new month's data" do
      before do
        gateway.upsert(Domain::CustomerSatisfaction.new(Time.new(2021, 11, 23), 1, 2, 3, 4, 5))
      end

      it "has the expected saved values" do
        saved_data = ActiveRecord::Base.connection.exec_query("SELECT * FROM customer_satisfaction")
        expect(saved_data.first["very_satisfied"]).to eq(1)
        expect(saved_data.first["satisfied"]).to eq(2)
        expect(saved_data.first["neither"]).to eq(3)
        expect(saved_data.first["dissatisfied"]).to eq(4)
        expect(saved_data.first["very_dissatisfied"]).to eq(5)
      end

      it "to ensure datetime is unique, the date saved is the 1st of the month" do
        saved_data = ActiveRecord::Base.connection.exec_query("SELECT month FROM customer_satisfaction")
        expect(saved_data.first["month"].strftime("%Y-%m-%d")).to eq("2021-11-01")
      end

      it "has a second row for a new month's data" do
        gateway.upsert(Domain::CustomerSatisfaction.new(Time.new(2021, 9, 0o5), 100, 50, 3, 4, 5))
        saved_data = ActiveRecord::Base.connection.exec_query("SELECT * FROM customer_satisfaction ORDER BY month DESC")
        expect(saved_data.length).to eq(2)
        expect(saved_data.last["very_satisfied"]).to eq(100)
      end
    end

    context "when sending data with the same month/year" do
      before do
        gateway.upsert(Domain::CustomerSatisfaction.new(Time.new(2021, 9, 0o5), 100, 50, 3, 4, 5))
        gateway.upsert(Domain::CustomerSatisfaction.new(Time.new(2021, 9, 0o5), 755, 125, 51, 69, 81))
      end

      let(:saved_data) do
        ActiveRecord::Base.connection.exec_query("SELECT * FROM customer_satisfaction ")
      end

      it "saves only a single record" do
        expect(saved_data.length).to eq(1)
      end

      it "the values are for the updates" do
        expect(saved_data.first["very_satisfied"]).to eq(755)
        expect(saved_data.first["satisfied"]).to eq(125)
        expect(saved_data.first["neither"]).to eq(51)
        expect(saved_data.first["dissatisfied"]).to eq(69)
        expect(saved_data.first["very_dissatisfied"]).to eq(81)
      end
    end
  end

  describe "#fetch" do
    before do
      gateway.upsert(Domain::CustomerSatisfaction.new(Time.new(2021, 9, 0o5), 111, 51, 3, 4, 5))
      gateway.upsert(Domain::CustomerSatisfaction.new(Time.new(2021, 10, 0o5), 222, 52, 3, 4, 5))
    end

    it "returns the values inserted into the table" do
      expect(gateway.fetch.first["very_satisfied"]).to eq(111)
      expect(gateway.fetch.first["satisfied"]).to eq(51)
      expect(gateway.fetch.last["very_satisfied"]).to eq(222)
      expect(gateway.fetch.last["satisfied"]).to eq(52)
    end

    it "return the date time converted into a string of ('YYYY-MM')" do
      expect(gateway.fetch.first["month"]).to eq("2021-09")
      expect(gateway.fetch.last["month"]).to eq("2021-10")
    end
  end
end
