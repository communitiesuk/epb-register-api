describe Gateway::OpenDataLogGateway do
  context "when there is no log data in the database insert it and return the statistics" do
    let(:gateway) { described_class.new }

    let(:statistics) { gateway.fetch_log_statistics }
    let(:latest_statistics) { gateway.fetch_latest_statistics }

    let(:latest_task_id) { gateway.fetch_latest_task_id }

    before(:all) do
      gateway = described_class.new
      report_type = "CEPC"

      gateway.create("0000-0000-0000-0000-0001", 1, report_type)
      gateway.create("0000-0000-0000-0000-0002", 1, report_type)
      gateway.create("0000-0000-0000-0000-0004", 1, report_type)
      gateway.create("0000-0000-0000-0000-0004", 2, report_type)
      gateway.create("0000-0000-0000-0000-0004", 2, report_type)
      gateway.create("0000-0000-0000-0000-0009", 3, %w[RdSAP SAP])
    end

    it "returns the statistics for the latest task only" do
      expect(latest_statistics["task_id"].to_i).to eq(3)
    end

    it "returns the correct count in the statistics " do
      expect(statistics.count).to eq(3)
      expect(statistics[0]["num_rows"]).to eq(3)
      expect(statistics[1]["num_rows"]).to eq(2)
    end

    it "returns the the today as the created at date " do
      expect(statistics[0]["date_start"].to_time.strftime("%F")).to eq(
        Time.now.strftime("%F"),
      )
    end

    it "returns the report types" do
      expect(statistics[0]["report_type"]).to eq("CEPC")
    end

    it "returns an execution time" do
      expect(statistics[0]["execution_time"]).not_to be_nil
    end

    it "returns an the task ids" do
      expect(statistics[0]["task_id"]).to eq(1)
      expect(statistics[1]["task_id"]).to eq(2)
    end

    it "returns the latest task Id" do
      expect(gateway.fetch_new_task_id(2)).to eq(2)
    end

    it "returns the latest task Id as 1" do
      expect(gateway.fetch_new_task_id).to eq(4)
    end

    it "returns the comma delimited string for report type of an array" do
      expect(statistics[2]["report_type"]).to eq("RdSAP,SAP")
    end

    it "returns the Id of the task that has just been run" do
      expect(gateway.fetch_latest_task_id).to eq(3)
    end

    it "returns a new task Id incremented from the last if you do not pass an integer" do
      expect(gateway.fetch_new_task_id("a")).to eq(4)
    end
  end

  context "when the log table is empty" do
    let(:gateway) { Gateway::OpenDataLogGateway.new }

    before do
      ActiveRecord::Base.connection.exec_query("TRUNCATE TABLE open_data_logs")
    end

    it "returns the latest task Id as 1" do
      expect(gateway.fetch_new_task_id).to eq(1)
    end
  end
end
