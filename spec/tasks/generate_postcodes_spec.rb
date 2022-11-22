describe "generate_postcodes rake" do
  include RSpecRegisterApiServiceMixin

  context "when calling the rake task in production" do
    before do
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:write)
      ENV["STAGE"] = "production"
    end

    after do
      ENV["STAGE"] = "test"
    end

    let!(:exported_data) do
      ActiveRecord::Base.connection.exec_query("SELECT * FROM postcode_geolocation")
    end

    it "raises an error and does not add anything to the database" do
      expect { get_task("dev_data:generate_postcodes").invoke }.to raise_error(
        StandardError,
      ).with_message("This task can only be run if the STAGE is test, development, integration or staging")
      expect(exported_data.rows.length).to eq(0)
    end
  end

  context "when calling the rake task in test (not production)" do
    before do
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:write)
      ActiveRecord::Base.connection.exec_query("INSERT INTO postcode_outcode_geolocations (outcode, latitude, longitude) VALUES('B34', '52', '-1'),('G65', '51', '-2'),('NH8', '53', '1');")
      get_task("dev_data:generate_postcodes").invoke
    end

    let!(:exported_data) do
      ActiveRecord::Base.connection.exec_query("SELECT * FROM postcode_geolocation")
    end

    it "loads the seed data into the database" do
      expect(exported_data.rows.length).to eq(3)
    end
  end
end
