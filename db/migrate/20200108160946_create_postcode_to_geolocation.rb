class CreatePostcodeToGeolocation < ActiveRecord::Migration[6.0]
  def change
    create_table :postcode_geolocation, primary_key: "postcode", id: :string do |t|
      t.decimal :latitude
      t.decimal :longitude
    end
  end
end
