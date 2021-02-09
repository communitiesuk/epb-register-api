describe "Gateway::OpenDataLogGateway" do
  context "when there is no log data in the database insert a row" do
    before(:all) do
      gateway = Gateway::OpenDataLogGateway.new
      gateway.insert("0000-0000-0000-0000-0001", 1)
      gateway.insert("0000-0000-0000-0000-0002", 2)
    end

    let(:log_data) do
      log_data =
        ActiveRecord::Base.connection.execute "SELECT * FROM open_data_logs"
    end

    it "should return a row of the newly inserted data" do
      expect(log_data.count).to eq(2)
    end

    it "should return the the correct asssessment_id " do
      expect(log_data[0]["assessment_id"]).to eq("0000-0000-0000-0000-0001")
      expect(log_data[1]["assessment_id"]).to eq("0000-0000-0000-0000-0002")
    end

    it "should return the the correct task id " do
      expect(log_data[0]["task_id"]).to eq(1)
      expect(log_data[1]["task_id"]).to eq(2)
    end

    it "should return the the today as the created_at date " do
      expect(log_data[0]["created_at"].to_datetime.strftime("%F")).to eq(
        DateTime.now.strftime("%F"),
      )
      expect(log_data[1]["created_at"].to_datetime.strftime("%F")).to eq(
        DateTime.now.strftime("%F"),
      )
    end

    it "should return a create_at whose datetime increments " do
      expect(log_data[1]["created_at"].to_datetime).to be >
        log_data[0]["created_at"].to_datetime
    end
  end

  context "when there is an existing log data entry in the database " do
  end
end
