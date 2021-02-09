describe "Gateway::OpenDataLogGateway" do
    context "when there is no log data in the database insert a row" do

      before(:all) do
        gateway = Gateway::OpenDataLogGateway.new
        expectation = gateway.insert("0000-0000-0000-0000-0001",1)
      end

      let(:log_data) {
        log_data = ActiveRecord::Base.connection.execute "SELECT * FROM open_data_logs"
      }

      it "should return a row of the newly inserted data" do
        expect(log_data.count).to eq(1)
      end

      it "should return the the correct asssessment id " do
        expect(log_data[0]["assessment_id"]).to eq("0000-0000-0000-0000-0001")
      end

      it "should return the the today as the created at date " do
        expect(log_data[0]["created_at"].to_datetime.strftime("%F")).to eq(DateTime.now.strftime("%F"))
      end

    end

    context "when there is an existing log data entry in the database " do


    end

  end
