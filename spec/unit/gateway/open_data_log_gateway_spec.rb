describe "Gateway::OpenDataLogGateway" do
  context "when there is no log data in the database insert it and return the statistics" do
    let(:statistics) do
      gateway = Gateway::OpenDataLogGateway.new
      gateway.get_statistics
    end

    before(:all) do
      gateway = Gateway::OpenDataLogGateway.new
      gateway.insert("0000-0000-0000-0000-0001", 1)
      gateway.insert("0000-0000-0000-0000-0002", 1)
      gateway.insert("0000-0000-0000-0000-0004", 1)
      gateway.insert("0000-0000-0000-0000-0004", 2)
    end

    it "should return the correct count in the statistics " do
      expect(statistics.count).to eq(2)
      expect(statistics[0]["num_rows"]).to eq(3)
      expect(statistics[1]["num_rows"]).to eq(1)
    end

    it "should return the the today as the created at date " do
      expect(statistics[0]["date_start"].to_datetime.strftime("%F")).to eq(
        DateTime.now.strftime("%F"),
      )
    end

    it "should return an execution time" do
      expect(statistics[0]["execution_time"]).not_to be_nil
    end

    it "should return an the task ids" do
      expect(statistics[0]["task_id"]).to eq(1)
      expect(statistics[1]["task_id"]).to eq(2)
    end
  end
end
