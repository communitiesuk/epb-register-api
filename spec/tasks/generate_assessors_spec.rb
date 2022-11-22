describe "generate_assessors rake" do
  include RSpecRegisterApiServiceMixin

  context "when calling the rake task in production" do
    before do
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:write)
      ENV["STAGE"] = "production"
      ActiveRecord::Base.connection.exec_query("INSERT INTO schemes (name) VALUES('CIBSE Certification Limited'),('ECMK'),('Elmhurst Energy Systems Ltd');")
      ActiveRecord::Base.connection.exec_query("INSERT INTO postcode_geolocation (postcode, latitude, longitude) VALUES('B34 2AA', '52', '-1'),('G65 1LG', '51', '-2'),('NH8 0LD', '53', '1');")
    end

    after do
      ENV["STAGE"] = "test"
    end

    let!(:exported_data) do
      ActiveRecord::Base.connection.exec_query("SELECT * FROM assessors")
    end

    it "raises an error and does not add anything to the database" do
      expect { get_task("dev_data:generate_assessors").invoke }.to raise_error(
        StandardError,
      ).with_message("This task can only be run if the STAGE is test, development, integration or staging")
      expect(exported_data.rows.length).to eq(0)
    end
  end

  context "when calling the rake task in test (not production)" do
    before do
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:write)
      ActiveRecord::Base.connection.exec_query("INSERT INTO schemes (name) VALUES('CIBSE Certification Limited'),('ECMK'),('Elmhurst Energy Systems Ltd');")
      get_task("dev_data:generate_assessors").invoke
    end

    let!(:exported_data) do
      ActiveRecord::Base.connection.exec_query("SELECT * FROM assessors ORDER BY scheme_assessor_id")
    end

    it "loads the seed data into the database" do
      expect(exported_data.rows.length).to eq(15)
    end
  end
end
