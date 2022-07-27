describe Gateway::PostcodeGeolocationGateway do
  let(:gateway) { described_class.new }

  before do
    allow($stdout).to receive(:puts)
  end

  describe "#clean_up" do
    it "deletes the tables without error" do
      expect { gateway.clean_up }.not_to raise_error
    end

    it "tables have been deleted " do
      gateway.clean_up
      result = ActiveRecord::Base.connection.exec_query("SELECT EXISTS (SELECT FROM pg_tables
WHERE tablename  in ('postcode_geolocation_tmp','postcode_geolocation_legacy','postcode_outcode_geolocations_tmp','postcode_outcode_geolocations_legacy'));")

      expect(result[0]["exists"]).to eq false
    end
  end
end
