class CreatePostcodeToGeolocation < ActiveRecord::Migration[6.0]
  def change
    create_table :postcode_geolocation do |t|
      t.string :postcode
      t.decimal :latitude
      t.decimal :longitude
    end
  end
end
