describe 'Integration::FilterAndOrderAssessorsByPostcode' do
  include RSpecAssessorServiceMixin

  context 'when searching for a postcode' do
    context 'and postcode_geolocation table is empty' do
      it 'returns an empty hash' do
        response = Gateway::PostcodesGateway.new.search('BF1 3AD')
        expect(response).to eq([])
      end
    end

    context ' and postcode_geolocation table is not empty' do
      let!(:populate_postcode_geolocation) do
        ActiveRecord::Base.connection.execute( "TRUNCATE TABLE postcode_geolocation")
        ActiveRecord::Base.connection.execute( "INSERT INTO postcode_geolocation (id, postcode, latitude, longitude) VALUES (1, 'BF1 3AD', 27.7172, -85.3240)")
      end

      it 'returns a single record' do
        response = Gateway::PostcodesGateway.new.search('BF1 3AD')
        expect(response).to eq([{"latitude"=>"27.7172", "longitude"=>"-85.3240"}])
      end
    end
  end
end
