describe Gateway::PostcodeGeolocationGateway do
  let(:gateway) { described_class.new }
  let(:db) { ActiveRecord::Base.connection }

  before do
    allow($stdout).to receive(:puts)
  end

  describe "#create_postcode_table" do
    it "creates the required temp table" do
      expect { gateway.create_postcode_table }.not_to raise_error
      expect(table_exists?("postcode_geolocation_tmp")).to eq true
    end
  end

  describe "#create_outcode_table" do
    it "creates the required temp table" do
      expect { gateway.create_outcode_table }.not_to raise_error
      expect(table_exists?("postcode_outcode_geolocations_tmp")).to eq true
    end
  end

  describe "#insert_postcode_batch" do
    before do
      gateway.create_postcode_table
      postcode_geolocation_buffer = []
      postcode = "SW1 2AS"
      region = "test"

      postcode_geolocation_buffer << [db.quote(postcode), "00000001", "12450", db.quote(region)].join(", ")
      gateway.insert_postcode_batch(postcode_geolocation_buffer)
    end

    it "saves the data into the postcode_geolocation_tmp table" do
      result = db.exec_query("SELECT * FROM postcode_geolocation_tmp")
      expect(result.length).to eq 1
      expect(result[0]["postcode"]).to eq "SW1 2AS"
      expect(result[0]["latitude"]).to eq 0o0000001
      expect(result[0]["longitude"].to_s).to eq "12450.0"
      expect(result[0]["region"]).to eq "test"
    end
  end

  describe "#insert_outcodes" do
    let(:outcodes) do
      { "CA8" =>
         { latitude: [54.977344], longitude: [-2.532215], region: ["North East"] },
        "BR8" =>
         { latitude: [51.403454, 51.399722],
           longitude: [0.148926, 0.145945],
           region: %w[London London] } }
    end

    before do
      gateway.create_outcode_table
      gateway.insert_outcodes(outcodes)
    end

    it "saves the data into the postcode_outcode_geolocations_tmp table" do
      result = db.exec_query("SELECT * FROM postcode_outcode_geolocations_tmp")
      expect(result.length).to eq 2
      expect(result[0]["latitude"].to_s).to eq 54.977344.to_s
      expect(result[1]["longitude"].to_s).to eq 0.1474355.to_s
      expect(result[0]["region"]).to eq "North East"
      expect(result[1]["region"]).to eq "London"
    end
  end

  describe "#clean_up" do
    it "deletes the tables without error" do
      expect { gateway.clean_up }.not_to raise_error
    end

    it "tables have been deleted" do
      gateway.clean_up
      result = ActiveRecord::Base.connection.exec_query("SELECT EXISTS (SELECT FROM pg_tables
WHERE tablename  in ('postcode_geolocation_tmp','postcode_geolocation_legacy','postcode_outcode_geolocations_tmp','postcode_outcode_geolocations_legacy'));")

      expect(result[0]["exists"]).to eq false
    end
  end
end

def table_exists?(table_name)
  ActiveRecord::Base.connection.exec_query("SELECT EXISTS (SELECT FROM pg_tables WHERE tablename  in ('#{table_name}'));")[0]["exists"]
end
