describe "Gateway::OpenDataLogGateway" do
  context "when there is no log data in the database insert it and return the statistics" do
    let(:gateway) { Gateway::OpenDataLogGateway.new }

    let(:statistics) { gateway.fetch_log_statistics }

    before(:all) do
      gateway = Gateway::OpenDataLogGateway.new
      report_type = "CEPC"

      gateway.create("0000-0000-0000-0000-0001", 1, report_type)
      gateway.create("0000-0000-0000-0000-0002", 1, report_type)
      gateway.create("0000-0000-0000-0000-0004", 1, report_type)
      gateway.create("0000-0000-0000-0000-0004", 2, report_type)
      gateway.create("0000-0000-0000-0000-0004", 2, report_type)
      gateway.create("0000-0000-0000-0000-0009", 3, %w[RdSAP SAP])
    end

    it "should return the correct count in the statistics " do
      expect(statistics.count).to eq(3)
      expect(statistics[0]["num_rows"]).to eq(3)
      expect(statistics[1]["num_rows"]).to eq(2)
    end

    it "should return the the today as the created at date " do
      expect(statistics[0]["date_start"].to_datetime.strftime("%F")).to eq(
        DateTime.now.strftime("%F"),
      )
    end

    it "should return the report types" do
      expect(statistics[0]["report_type"]).to eq("CEPC")
    end

    it "should return an execution time" do
      expect(statistics[0]["execution_time"]).not_to be_nil
    end

    it "should return an the task ids" do
      expect(statistics[0]["task_id"]).to eq(1)
      expect(statistics[1]["task_id"]).to eq(2)
    end

    it "should return the latest task Id" do
      expect(gateway.fetch_new_task_id(2)).to eq(2)
    end

    it "should should return the latest task Id as 1" do
      expect(gateway.fetch_new_task_id).to eq(4)
    end

    it "should should return the comma delimited string for report type of an array" do
      expect(statistics[2]["report_type"]).to eq("RdSAP,SAP")
    end

    it "should should return the latest task Id if you do not pass an integer" do
      expect(gateway.fetch_new_task_id("a")).to eq(4)
    end
  end

  context "when the log table is empty" do
    let(:gateway) { Gateway::OpenDataLogGateway.new }

    before do
      ActiveRecord::Base.connection.exec_query("TRUNCATE TABLE open_data_logs")
    end

    it "should should return the latest task Id as 1" do
      expect(gateway.fetch_new_task_id).to eq(1)
    end
  end
end
