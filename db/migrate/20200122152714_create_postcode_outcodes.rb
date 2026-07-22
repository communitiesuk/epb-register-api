class CreatePostcodeOutcodes < ActiveRecord::Migration[6.0]
  def change
    create_table :postcode_outcode_geolocations, primary_key: "outcode", id: :string do |t|
      t.decimal :latitude
      t.decimal :longitude
    end
  end
end
